# frozen_string_literal: true

module Sevgi
  module Graphics
    # Renderable text-like content inside an SVG element.
    class Content
      # XML 1.0 character-data validation and escaping helpers.
      # @api private
      module XML
        TERMINATOR = "]]>"
        TERMINATOR_SPLIT = "]]]]><![CDATA[>"
        private_constant :TERMINATOR, :TERMINATOR_SPLIT

        class << self
          def validate(value, seen = {}.compare_by_identity)
            return validate_string(value.to_s) unless value.is_a?(::Hash) || value.is_a?(::Array)

            validate_nested(value, seen) do
              value.is_a?(::Hash) ? value.each { |key, item|
                validate(key, seen)
                validate(item, seen)
              } : value.each { validate(it, seen) }
            end
          end

          def cdata(value) = validate_string(value.to_s).gsub(TERMINATOR, TERMINATOR_SPLIT)

          private

          def validate_nested(value, seen)
            ArgumentError.("Cyclic XML content is not supported") if seen.key?(value)

            seen[value] = true
            yield
          ensure
            seen.delete(value)
          end

          def validate_string(value)
            ArgumentError.("XML content must be valid UTF-8") unless value.valid_encoding?

            text = value.encode("UTF-8")
            if (codepoint = text.each_codepoint.find { !legal_codepoint?(it) })
              ArgumentError.("XML content contains illegal character U+#{format("%04X", codepoint)}")
            end

            text
          rescue ::EncodingError => e
            ArgumentError.("XML content must be valid UTF-8: #{e.message}")
          end

          def legal_codepoint?(codepoint)
            [0x9, 0xA, 0xD].include?(codepoint) ||
              (0x20..0xD7FF).cover?(codepoint) ||
              (0xE000..0xFFFD).cover?(codepoint) ||
              (0x10000..0x10FFFF).cover?(codepoint)
          end
        end
      end

      private_constant :XML

      # @!attribute [r] content
      #   @return [Object] wrapped content
      attr_reader :content

      # Creates content. All stringified payloads must contain legal XML 1.0 characters and valid UTF-8.
      # @param content [Object] wrapped content
      # @return [void]
      # @raise [Sevgi::ArgumentError] when content contains invalid encoding, illegal XML characters, or cycles
      def initialize(content)
        XML.validate(content)
        @content = content
      end

      # Copies content payload ownership for duplicated element trees.
      # @param original [Sevgi::Graphics::Content] source content
      # @return [void]
      def initialize_copy(original)
        @content = copy_payload(original.content)
        super
      end

      # Renders content with a renderer.
      # @abstract Subclasses implement content rendering.
      # @param _renderer [Object] renderer receiving output
      # @param _depth [Integer] current render depth
      # @return [void]
      # @raise [Sevgi::PanicError] when a subclass does not implement render
      def render(_renderer, _depth) = PanicError.("#{self.class}#render must be implemented")

      # Returns content as a string.
      # @return [String]
      def to_s = content.to_s

      def copy_payload(value, seen = {}.compare_by_identity)
        return value.dup if value.is_a?(::String)
        return value unless value.is_a?(::Hash) || value.is_a?(::Array)

        copy_nested(value, seen) do
          if value.is_a?(::Hash)
            value.to_h { |key, nested| [copy_payload(key, seen), copy_payload(nested, seen)] }
          else
            value.map { copy_payload(it, seen) }
          end
        end
      end

      def copy_nested(value, seen)
        ArgumentError.("Cannot duplicate cyclic content payload") if seen.key?(value)

        seen[value] = true
        yield
      ensure
        seen.delete(value)
      end

      private :copy_payload

      # @overload cdata(content)
      #   Builds CDATA content.
      #   Content values are stringified during rendering, and embedded CDATA terminators are split safely.
      #   @param content [Object] wrapped content
      #   @return [Sevgi::Graphics::Content::CData]
      def self.cdata(...) = CData.new(...)

      # Wraps content arguments, encoding non-content values.
      # Non-content values are stringified by encoded content before XML text escaping.
      # @param args [Array<Object>] content arguments
      # @return [Array<Sevgi::Graphics::Content>]
      def self.contents(*args) = args.map { it.is_a?(Content) ? it : encoded(it) }

      # @overload css(content)
      #   Builds CSS content.
      #   @param content [Hash] CSS rules
      #   @return [Sevgi::Graphics::Content::CSS]
      #   @raise [Sevgi::ArgumentError] when content is not a hash
      def self.css(...) = CSS.new(...)

      # @overload encoded(content)
      #   Builds XML text-encoded content.
      #   Arbitrary objects are stringified before XML text escaping.
      #   @param content [Object] wrapped content
      #   @return [Sevgi::Graphics::Content::Encoded]
      def self.encoded(...) = Encoded.new(...)

      # Joins content lines with newlines.
      # @param contents [Object, Array<Object>] content lines
      # @return [String]
      def self.text(contents) = Array(contents).join("\n")

      # @overload verbatim(content)
      #   Builds verbatim content.
      #   @param content [Object] wrapped content
      #   @return [Sevgi::Graphics::Content::Verbatim]
      def self.verbatim(...) = Verbatim.new(...)

      # CDATA section content.
      class CData < Content
        # Renders CDATA content.
        # Embedded `]]>` terminators are split across adjacent CDATA sections so the output remains valid XML.
        # @param renderer [Object] renderer receiving output
        # @param depth [Integer] current render depth
        # @return [void]
        def render(renderer, depth)
          depth += 1

          renderer.append(depth, "<![CDATA[")
          renderer.append(depth + 1, *Array(content).map { safe(it) })
          renderer.append(depth, "]]>")
        end

        private

        def safe(value) = XML.cdata(value)
      end

      # CSS content rendered inside a CDATA section.
      class CSS < Content
        # Creates CSS content.
        # @param content [Hash] CSS rules
        # @return [void]
        # @raise [Sevgi::ArgumentError] when content is not a hash
        def initialize(content)
          ArgumentError.("CSS content must be a hash: #{content}") unless content.is_a?(::Hash)

          super
        end

        # rubocop:disable Metrics/MethodLength
        # Renders CSS content.
        # @param renderer [Object] renderer receiving output
        # @param depth [Integer] current render depth
        # @return [void]
        # @raise [Sevgi::ArgumentError] when a style value cannot be rendered
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

      # XML text-encoded content.
      class Encoded < Content
        # Returns XML text-encoded content.
        # @return [String]
        def to_s = XML.validate(content).encode(xml: :text)

        # Renders encoded text content.
        # @param renderer [Object] renderer receiving output
        # @param depth [Integer] current render depth
        # @return [void]
        def render(renderer, depth) = renderer.append(depth + 1, to_s)
      end

      # Verbatim content rendered without XML text encoding.
      class Verbatim < Content
        # Returns validated verbatim content.
        # @return [String]
        # @raise [Sevgi::ArgumentError] when content contains invalid encoding or illegal XML characters
        def to_s = XML.validate(content)

        # Renders verbatim content.
        # @param renderer [Object] renderer receiving output
        # @param depth [Integer] current render depth
        # @return [void]
        def render(renderer, depth) = renderer.append(depth + 1, to_s)
      end
    end
  end
end
