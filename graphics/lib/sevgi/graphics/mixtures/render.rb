# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # DSL helpers for rendering SVG documents and children.
      module Render
        # SVG source renderer.
        # @api private
        class Renderer
          # Default renderer options.
          DEFAULTS = {indent: "  ", linelength: 140, style: :hybrid}.freeze

          # Attribute rendering strategies.
          # @api private
          module Attributes
            # Block-style attribute renderer.
            # @api private
            module Block
              # Renders attributes in block form.
              # @param element [Sevgi::Graphics::Element] rendered element
              # @param depth [Integer] element depth
              # @return [void]
              def attributes(element, depth)
                attributes_block(element, depth, element.attributes.to_xml_lines)
              end
            end

            # Hybrid attribute renderer.
            # @api private
            module Hybrid
              # Renders attributes inline or in block form according to line length.
              # @param element [Sevgi::Graphics::Element] rendered element
              # @param depth [Integer] element depth
              # @return [void]
              def attributes(element, depth)
                if attributes_as_block?(lines = element.attributes.to_xml_lines, depth)
                  attributes_block(element, depth, lines)
                else
                  attributes_inline(element, depth, lines)
                end
              end

              # Reports whether attributes should be rendered in block form.
              # @param lines [Array<String>] rendered attribute lines
              # @param depth [Integer] element depth
              # @return [Boolean]
              def attributes_as_block?(lines, depth)
                linelength(lines, depth) > options[:linelength]
              end

              # Returns the effective inline line length.
              # @param lines [Array<String>] rendered attribute lines
              # @param depth [Integer] element depth
              # @return [Integer]
              def linelength(lines, depth)
                indent(depth).length + lines.sum(&:length)
              end
            end

            # Inline attribute renderer.
            # @api private
            module Inline
              # Renders attributes inline.
              # @param element [Sevgi::Graphics::Element] rendered element
              # @param depth [Integer] element depth
              # @return [void]
              def attributes(element, depth)
                attributes_inline(element, depth, element.attributes.to_xml_lines)
              end
            end
          end

          private_constant :Attributes

          ELEMENTS_WITH_INLINE_CONTENT = %i[title].freeze
          ELEMENTS_WITH_BLOCK_CONTENT = %i[style].freeze
          SEPARATOR = "\n"

          private_constant :ELEMENTS_WITH_INLINE_CONTENT, :ELEMENTS_WITH_BLOCK_CONTENT, :SEPARATOR

          # @return [Sevgi::Graphics::Element] root element
          attr_reader :root

          # @return [Hash] renderer options
          attr_reader :options

          # @return [Array<Array<String>>] buffered output lines
          attr_reader :output

          # Inline-content output splice helper.
          # @api private
          class Inlines
            # Inline mark with start, stop, and depth.
            Mark = Struct.new(:start, :stop, :depth)

            # Creates an inline splice tracker.
            # @return [void]
            def initialize
              @marks = []
              @stack = []
            end

            # Starts an inline splice range.
            # @param index [Integer] output index
            # @param depth [Integer] element depth
            # @return [Sevgi::Graphics::Mixtures::Render::Renderer::Inlines::Mark] opened mark
            def start(index, depth)
              Mark.new(start: index, depth:).tap do |mark|
                @marks << mark
                @stack << mark
              end
            end

            # Ends the innermost inline splice range.
            # @param index [Integer] output index
            # @return [Integer]
            # @raise [Sevgi::PanicError] when no inline range is open
            def stop(index)
              mark = @stack.pop
              PanicError.("Inline content range was not opened") unless mark

              mark.stop = index
            end

            # Joins marked output ranges into inline content.
            # @param output [Array<Array<String>, nil>] renderer output buffer
            # @param indent [String] indentation unit
            # @param separator [String] line separator
            # @return [Array<Array<String>, nil>, nil]
            # @raise [Sevgi::PanicError] when an inline range was not closed
            def join(output, indent:, separator:)
              return if @marks.empty?

              @marks.reverse_each { |mark| join_mark(output, mark, indent:, separator:) }

              output.compact!
            end

            private

            def join_mark(output, mark, indent:, separator:)
              PanicError.("Inline content range was not closed") unless mark.stop

              ((mark.start + 1)..mark.stop).each do |index|
                lines = output[index]
                next unless lines

                lines.map! { |line| line.delete_prefix(indent * (mark.depth + 1)) }
                output[mark.start][-1] += lines.join(separator)
                output[index] = nil
              end
            end
          end

          # @overload initialize(root, **options)
          #   Creates a renderer.
          #   @param root [Sevgi::Graphics::Element] root element
          #   @param options [Hash] renderer options
          #   @option options [String] :indent indentation unit
          #   @option options [Integer] :linelength hybrid attribute line length
          #   @option options [Symbol] :style attribute style, one of :hybrid, :inline, or :block
          #   @return [void]
          #   @raise [Sevgi::ArgumentError] when style is missing or unsupported
          def initialize(root, **)
            @root = root
            @options = DEFAULTS.merge(**)
            @output = []
            @inlines = Inlines.new

            build
          end

          # @overload call(root, **options)
          #   Renders a root element.
          #   @param root [Sevgi::Graphics::Element] root element
          #   @param options [Hash] renderer options
          #   @return [String] SVG source
          #   @raise [Sevgi::ArgumentError] when style is missing or unsupported
          def self.call(root, **) = new(root, **).call(*root.class.preambles)

          # Appends rendered lines to the output buffer.
          # @param depth [Integer, nil] indentation depth
          # @param lines [Array<String>] rendered lines
          # @return [Array<Array<String>>, nil]
          def append(depth, *lines)
            return if lines.empty?

            output.append(lines.map { "#{indent(depth) if depth}#{it}" })
          end

          # Renders the document.
          # @param preambles [Array<String>] preamble lines
          # @return [String] SVG source
          def call(*preambles)
            output.append(preambles) unless preambles.empty?

            root.Traverse(
              0,
              proc { |element, depth| render_leave(element, depth) }
            ) { |element, depth| render_enter(element, depth) }

            join
          end

          private

          attr_reader :inlines

          def attributes_block(element, depth, lines)
            return attributes_inline(element, depth, lines) if lines.empty?

            append(depth, "<#{element.name}")
            append(depth + 1, *lines)
            append(depth, ">") unless childless?(element)
          end

          def attributes_inline(element, depth, lines)
            line = "<#{[element.name, *lines].join(" ")}"

            if childless?(element)
              closed
              append(depth, "#{line}/>")
            else
              append(depth, "#{line}>")
            end
          end

          def build
            ArgumentError.("Missing style") unless options[:style]

            case options[:style]
            when :hybrid
              extend(Attributes::Hybrid)
            when :inline
              extend(Attributes::Inline)
            when :block
              extend(Attributes::Block)
            else
              ArgumentError.("Unrecognized style: #{options[:style]}")
            end

            unclosed
          end

          def childless?(element)
            element.children.empty? && element.contents.empty?
          end

          def closed = @closed = true

          def closed? = @closed.tap { unclosed }

          def contents(element, depth)
            return if element.contents.empty?

            if floating?(element)
              append(depth, *element.contents.map(&:to_s))
              closed
            else
              element.contents.each { |content| content.render(self, depth) }
            end
          end

          def floating?(element) = element.Is?(:_)

          def inline_content?(element)
            return false if ELEMENTS_WITH_BLOCK_CONTENT.include?(element.name)
            return false if floating?(element)

            element.contents.size == 1 || ELEMENTS_WITH_INLINE_CONTENT.include?(element.name)
          end

          def indent(depth)
            options[:indent] * depth
          end

          def join
            inlines.join(output, indent: options[:indent], separator: SEPARATOR)
            output.join(SEPARATOR)
          end

          def render_enter(element, depth)
            attributes(element, depth) unless floating?(element)
            inlines.start(output.size - 1, depth) if inline_content?(element)
            contents(element, depth)
          end

          def render_leave(element, depth)
            inlines.stop(output.size) if (inlined = inline_content?(element))
            return if closed? || floating?(element)

            if childless?(element)
              append(depth, "/>")
            elsif inlined
              append(nil, "</#{element.name}>")
            else
              append(depth, "</#{element.name}>")
            end
          end

          def unclosed = @closed = false
        end

        private_constant :Renderer

        # @overload Render(**options)
        #   Renders this element as SVG source.
        #   Elements with inline text content may also contain inline children such as `tspan`; the renderer keeps those
        #   descendants in the same text line. Whitespace inside content objects is preserved as given, and encoded
        #   content is XML-escaped unless a verbatim content object is used.
        #   @param options [Hash] renderer options
        #   @return [String] SVG source
        #   @raise [Sevgi::ArgumentError] when style is missing or unsupported
        def Render(**) = Renderer.(self, **)

        # Renders only this element's children.
        # Child render output preserves each child's text whitespace and inline mixed-content formatting.
        # @param separator [String] separator between child documents
        # @return [String] rendered children
        def RenderChildren(separator = "\n\n") = children.map(&:Render).join(separator)
      end
    end
  end
end
