# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Render
        class Renderer
          DEFAULTS = { indent: "  ", linelength: 140, style: :hybrid }.freeze

          module Attributes
            module Block
              def attributes(element, depth)
                attributes_block(element, depth, element.attributes.to_xml_lines)
              end
            end

            module Hybrid
              def attributes(element, depth)
                if attributes_as_block?(lines = element.attributes.to_xml_lines, depth)
                  attributes_block(element, depth, lines)
                else
                  attributes_inline(element, depth, lines)
                end
              end

              def linelength(lines, depth)
                indent(depth).length + lines.sum(&:length)
              end

              def attributes_as_block?(lines, depth)
                linelength(lines, depth) > options[:linelength]
              end
            end

            module Inline
              def attributes(element, depth)
                attributes_inline(element, depth, element.attributes.to_xml_lines)
              end
            end
          end

          private_constant :Attributes

          attr_reader :root, :options, :output

          def initialize(root, **)
            @root    = root
            @options = DEFAULTS.merge(**)
            @output  = []

            build
          end

          def call(*preambles)
            output.append(preambles) unless preambles.empty?

            root.Traverse(
              0,
              proc { |element, depth| render_leave(element, depth) }
            )      { |element, depth| render_enter(element, depth) }

            output.join("\n")
          end

          def append(depth, *lines)
            unless lines.empty?
              indentation = indent(depth)
              output.append(lines.map { "#{indentation}#{_1}" })
            end
          end

          private

          def build
            ArgumentError.("Missing style") unless options[:style]

            case options[:style]
            when :hybrid then extend(Attributes::Hybrid)
            when :inline then extend(Attributes::Inline)
            when :block  then extend(Attributes::Block)
            else              ArgumentError.("Unrecognized style: #{options[:style]}")
            end

            unclosed
          end

          def childless?(element)
            element.children.empty? && element.contents.empty?
          end

          def closed  = @closed = true

          def closed? = @closed.tap { unclosed }

          def attributes_block(element, depth, lines)
            append(depth, "<#{element.name}")
            append(depth + 1, *lines)
            append(depth, ">") unless childless?(element)
          end

          def attributes_inline(element, depth, lines)
            line = "<#{[ element.name, *lines ].join(" ")}"

            append(depth, (childless?(element) ? "#{line}/>".tap { closed } : "#{line}>"))
          end

          def contents(element, depth)
            return if element.contents.empty?

            if floating?(element)
              append(depth, *element.contents.map(&:to_s))
            else
              element.contents.each { |content| content.render(self, depth) }
            end
          end

          def indent(depth)
            options[:indent] * depth
          end

          def render_enter(element, depth)
            attributes(element, depth) unless floating?(element)
            contents(element, depth)
          end

          def render_leave(element, depth)
            return if closed? || floating?(element)

            append(depth, (childless?(element) ? "/>" : "</#{element.name}>").to_s)
          end

          def unclosed = @closed = false

          def floating?(element) = element.name == :"-"

          class << self
            def call(root, **) = new(root, **).call(*root.class.preambles)
          end
        end

        private_constant :Renderer

        module InstanceMethods
          def Render(**) = Renderer.(self, **)
        end
      end
    end
  end
end
