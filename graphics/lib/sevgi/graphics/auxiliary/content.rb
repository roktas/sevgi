# frozen_string_literal: true

module Sevgi
  module Graphics
    class Content
      attr_reader :content

      def initialize(content) = @content = content

      def render(_renderer, _depth) = PanicError.("#{self.class}#render must be implemented")

      def to_s = content.to_s

      def self.cdata(...) = CData.new(...)

      def self.contents(*args) = args.map { it.is_a?(Content) ? it : encoded(it) }

      def self.css(...) = CSS.new(...)

      def self.encoded(...) = Encoded.new(...)

      def self.text(contents) = Array(contents).join("\n")

      def self.verbatim(...) = Verbatim.new(...)

      class CData < Content
        def render(renderer, depth)
          depth += 1

          renderer.append(depth, "<![CDATA[")
          renderer.append(depth + 1, *Array(content))
          renderer.append(depth, "]]>")
        end
      end

      class CSS < Content
        def initialize(content)
          ArgumentError.("CSS content must be a hash: #{content}") unless content.is_a?(::Hash)

          super
        end

        # rubocop:disable Metrics/MethodLength
        def render(renderer, depth)
          depth += 1

          renderer.append(depth, "<![CDATA[")

          depth += 1
          content.each do |rule, styles|
            case styles
            when ::Hash
              renderer.append(depth, "#{rule} {")
              renderer.append(depth + 1, *styles.map { |key, value| "#{key}: #{value};" })
              renderer.append(depth, "}")
            when ::String, ::Symbol, ::Numeric
              renderer.append(depth, "#{rule}: #{styles};")
            else
              ArgumentError.("Malformed style: #{styles}")
            end
          end

          depth -= 1

          renderer.append(depth, "]]>")
        end
        # rubocop:enable Metrics/MethodLength
      end

      class Encoded < Content
        def to_s = content.encode(xml: :text)

        def render(renderer, depth) = renderer.append(depth + 1, to_s)
      end

      class Verbatim < Content
        def render(renderer, depth) = renderer.append(depth + 1, to_s)
      end
    end
  end
end
