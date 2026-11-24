# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # DSL helpers for rendering SVG documents and children.
      module Render
        # Validates SVG renderer formatting options.
        # @api private
        module Options
          DEFAULTS = {indent: "  ", linelength: 140, style: :hybrid}.freeze
          STYLES = %i[hybrid inline block].freeze
          private_constant :STYLES

          # Validates and normalizes renderer formatting options.
          # @param options [Hash] caller options
          # @return [Hash] frozen normalized options
          # @raise [Sevgi::ArgumentError] when an option is invalid
          def self.validate(**options)
            options = DEFAULTS.merge(options)
            validate_keys!(options)
            options[:indent] = valid_indent(options[:indent])
            validate_linelength!(options[:linelength])
            validate_style!(options[:style])
            options.freeze
          end

          def self.validate_keys!(options)
            unknown = options.keys - DEFAULTS.keys
            ArgumentError.("Unknown renderer options: #{unknown.join(", ")}") unless unknown.empty?
          end

          def self.valid_indent(indent)
            unless indent.is_a?(::String) && /\A[\t\n\r ]*\z/.match?(indent)
              ArgumentError.("Renderer indent must contain only XML whitespace")
            end

            XML.text(indent, context: "Renderer indent")
          end

          def self.validate_linelength!(linelength)
            return if linelength.is_a?(::Integer) && linelength >= 0

            ArgumentError.("Renderer linelength must be a non-negative Integer")
          end

          def self.validate_style!(style)
            ArgumentError.("Unrecognized style: #{style}") unless STYLES.include?(style)
          end

          private_class_method :valid_indent, :validate_keys!, :validate_linelength!, :validate_style!
        end

        # Renders inline element contents and children directly into one line buffer.
        # @api private
        class InlineBuffer
          SEPARATOR = "\n"
          private_constant :SEPARATOR

          def initialize(buffer)
            @buffer = buffer
          end

          def append(_depth, *lines)
            @buffer << lines.join(SEPARATOR) unless lines.empty?
          end

          def render(element, contents, children, depth)
            contents.each { it.render(self, depth) }
            children.each { render_child(it, depth + 1) }
            @buffer << "</#{element.name}>"
          end

          private

          def render_child(element, depth)
            children = Element.send(:tree_children, element)
            contents = element.contents
            return render_floating(contents, children, depth) if element.name == :_

            tag = inline_tag(element)
            return @buffer << "<#{tag}/>" if children.empty? && contents.empty?

            @buffer << "<#{tag}>"
            render(element, contents, children, depth)
          end

          def render_floating(contents, children, depth)
            contents.each { it.render(self, depth) }
            children.each { render_child(it, depth + 1) }
          end

          def inline_tag(element)
            lines = element.attributes.send(:xml_lines)
            lines.empty? ? element.name.to_s : "#{element.name} #{lines.join(" ")}"
          end
        end

        # Direct recursive SVG source renderer without post-pass inline splicing.
        # @api private
        class Renderer
          SVG_NAMESPACE = "http://www.w3.org/2000/svg"
          ELEMENTS_WITH_INLINE_CONTENT = %i[title].freeze
          ELEMENTS_WITH_BLOCK_CONTENT = %i[style].freeze
          SEPARATOR = "\n"
          private_constant :ELEMENTS_WITH_BLOCK_CONTENT, :ELEMENTS_WITH_INLINE_CONTENT, :SEPARATOR, :SVG_NAMESPACE

          attr_reader :root, :options

          def self.call(root, **) = new(root, **).call(*root.class.preambles)
          def self.fragment(root, **options) = new(root, **options).call
          def self.validate(**options) = Options.validate(**options)
          private_class_method :validate

          def initialize(root, **)
            @root = root
            @options = Options.validate(**)
            @lines = []
            @indents = Hash.new { |cache, depth| cache[depth] = @options[:indent] * depth }
          end

          def append(depth, *lines)
            return if lines.empty?

            prefix = depth && depth >= 0 ? indent(depth) : ""
            @lines.concat(lines.map { "#{prefix}#{it}" })
          end

          def call(*preambles)
            @lines.concat(preambles.map { XML.text(it, context: "XML preamble") }) unless preambles.empty?
            render_block(@root, 0, parent_default_namespace(@root.parent))
            XML.text(@lines.join(SEPARATOR), context: "SVG output")
          end

          private

          def render_block(element, depth, default_ns)
            ns = element_namespace(element, default_ns)
            children = Element.send(:tree_children, element)
            return render_floating(element.contents, children, depth, ns) if element.name == :_

            contents = element.contents
            return @lines << emit_tag(element, depth, "/>") if children.empty? && contents.empty?

            emit_element(element, contents, children, depth, ns)
          end

          def emit_element(element, contents, children, depth, ns)
            open_line = emit_tag(element, depth, ">")
            return emit_inline(element, open_line, contents, children, depth) if inline_content?(element, contents, ns)

            @lines << open_line
            contents.each { it.render(self, depth) }
            children.each { render_block(it, depth + 1, ns) }
            @lines << "#{indent(depth)}</#{element.name}>"
          end

          def emit_inline(element, open_line, contents, children, depth)
            buffer = +open_line
            InlineBuffer.new(buffer).render(element, contents, children, depth)
            @lines << buffer
          end

          def render_floating(contents, children, depth, ns)
            contents.each { it.render(self, depth - 1) }
            children.each { render_block(it, depth + 1, ns) }
          end

          def emit_tag(element, depth, suffix)
            attrs = element.attributes.send(:xml_lines)
            if block_attributes?(depth, attrs)
              emit_block_attributes(element.name, attrs, depth)
              "#{indent(depth)}#{suffix}"
            else
              "#{indent(depth)}<#{inline_tag(element.name, attrs)}#{suffix}"
            end
          end

          def emit_block_attributes(name, attrs, depth)
            @lines << "#{indent(depth)}<#{name}"
            attrs.each { @lines << "#{indent(depth + 1)}#{it}" }
          end

          def inline_tag(name, attrs)
            attrs.empty? ? name.to_s : "#{name} #{attrs.join(" ")}"
          end

          def block_attributes?(depth, attrs)
            return false if attrs.empty?

            @options[:style] == :block ||
              (@options[:style] == :hybrid && indent(depth).length + attrs.sum(&:length) > @options[:linelength])
          end

          def inline_content?(element, contents, ns)
            return false if block_content?(element, ns)

            contents.any? || ELEMENTS_WITH_INLINE_CONTENT.include?(element.name)
          end

          def block_content?(element, ns)
            return false unless ELEMENTS_WITH_BLOCK_CONTENT.include?(element.name)

            ns.nil? || ns.to_s.empty? || ns == SVG_NAMESPACE
          end

          def element_namespace(element, inherited)
            element.attributes.has?(:xmlns) ? element.attributes[:xmlns] : inherited
          end

          def parent_default_namespace(element)
            while element.is_a?(Element)
              return element.attributes[:xmlns] if element.attributes.has?(:xmlns)

              element = element.parent
            end
          end

          def indent(depth) = @indents[depth]
        end

        private_constant :InlineBuffer, :Options, :Renderer

        # @overload Render(**options)
        #   Renders this element as SVG source.
        #   Elements with inline text content can also contain inline children such as `tspan`. The renderer keeps those
        #   descendants in the same text line. Whitespace inside content objects is preserved as given, and encoded
        #   content is XML-escaped unless a verbatim content object is used. SVG `style` elements use block content.
        #   same-named elements under a foreign default namespace retain ordinary inline text formatting.
        #   @example Keep every attribute on the element's opening line
        #     SVG(:minimal) { rect id: "card", width: 80, height: 40 }.Render(style: :inline)
        #   @param options [Hash] renderer options
        #   @option options [String] :indent ("  ") XML-whitespace indentation unit
        #   @option options [Integer] :linelength (140) non-negative line length that switches hybrid attributes to block
        #     style
        #   @option options [Symbol] :style (:hybrid) attribute layout: `:hybrid`, `:inline`, or `:block`
        #   @return [String] SVG source
        #   @raise [Sevgi::ArgumentError] when options, preambles, names, attributes, or content are invalid XML
        def Render(**) = Renderer.(self, **)

        # Renders only this element's children.
        # Child render output omits document preambles and preserves each child's text whitespace and inline
        # mixed-content formatting.
        # @example Render child fragments with block-style attributes
        #   Sevgi::Graphics.SVG(:minimal) { rect id: "one" }.RenderChildren(style: :block, indent: "\t")
        # @param separator [String] separator between child documents
        # @param options [Hash] renderer options applied to every child fragment
        # @option options [String] :indent ("  ") XML-whitespace indentation unit
        # @option options [Integer] :linelength (140) non-negative line length that switches hybrid attributes to block
        #   style
        # @option options [Symbol] :style (:hybrid) attribute layout: `:hybrid`, `:inline`, or `:block`
        # @return [String] rendered child fragments
        # @raise [Sevgi::ArgumentError] when separator, options, or rendered child data is invalid
        def RenderChildren(separator = "\n\n", **options)
          ArgumentError.("SVG fragment separator must be a String") unless separator.is_a?(::String)

          separator = XML.text(separator, context: "SVG fragment separator")
          Renderer.send(:validate, **options)
          children.map { Renderer.fragment(it, **options) }.join(separator)
        end
      end
    end
  end
end
