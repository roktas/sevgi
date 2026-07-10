# frozen_string_literal: true

module Sevgi
  module Graphics
    # Renderable text-like content inside an SVG element.
    class Content
      # @!attribute [r] content
      #   @return [Object] wrapped content
      attr_reader :content

      # Creates content.
      # @param content [Object] wrapped content
      # @return [void]
      def initialize(content) = @content = content

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

      def copy_payload(value)
        case value
        when ::Hash
          value.to_h { |key, nested| [copy_payload(key), copy_payload(nested)] }
        when ::Array
          value.map { copy_payload(it) }
        when ::String
          value.dup
        else
          value
        end
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
        TERMINATOR = "]]>"
        TERMINATOR_SPLIT = "]]]]><![CDATA[>"
        private_constant :TERMINATOR, :TERMINATOR_SPLIT

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

        def safe(value) = value.to_s.gsub(TERMINATOR, TERMINATOR_SPLIT)
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
        def to_s = content.to_s.encode(xml: :text)

        # Renders encoded text content.
        # @param renderer [Object] renderer receiving output
        # @param depth [Integer] current render depth
        # @return [void]
        def render(renderer, depth) = renderer.append(depth + 1, to_s)
      end

      # Verbatim content rendered without XML text encoding.
      class Verbatim < Content
        # Renders verbatim content.
        # @param renderer [Object] renderer receiving output
        # @param depth [Integer] current render depth
        # @return [void]
        def render(renderer, depth) = renderer.append(depth + 1, to_s)
      end
    end
  end
end
