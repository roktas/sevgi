# frozen_string_literal: true

module Sevgi
  module Graphics
    # Extensible protocol for renderable text-like content inside an SVG element. Use {.cdata}, {.css}, {.encoded}, or
    # {.verbatim} for built-in content, or subclass Content and implement {#render} for a custom serialization. Content
    # owns an immutable deep snapshot: strings and containers are copied, mutable leaf objects are stringified once
    # during construction, and {#content} returns caller-owned copies. Later mutations cannot change rendering or
    # invalidate the construction-time XML checks.
    #
    # @abstract Subclasses implement {#render} and expose their own construction API.
    # @example Choose a built-in content channel
    #   Sevgi::Graphics.SVG(:minimal) do
    #     text "A & B" # ordinary String arguments are encoded automatically
    #     text Sevgi::Graphics::Content.encoded("A & B")
    #     style Sevgi::Graphics::Content.cdata(".note { fill: red; }")
    #     style Sevgi::Graphics::Content.css(".note" => {fill: "red"})
    #     g Sevgi::Graphics::Content.verbatim("<title>trusted markup</title>")
    #   end
    # @example Define custom content that emits an SVG tspan
    #   class Emphasis < Sevgi::Graphics::Content
    #     def self.[](content) = send(:new, content)
    #
    #     def render(output, depth)
    #       text = Sevgi::Graphics::Content.encoded(to_s).to_s
    #       output.append(depth + 1, %(<tspan font-style="italic">#{text}</tspan>))
    #     end
    #   end
    #
    #   Sevgi::Graphics.SVG(:minimal) { text Emphasis["important & safe"] }.Render
    #
    #   # The renderer ignores Emphasis#render's return value. Custom content must escape inserted data itself.
    # @see https://sevgi.roktas.dev/documents/#content-safety Content safety guide
    class Content
      private_class_method :new

      # @overload cdata(content)
      #   Builds CDATA content.
      #   Mutable objects are stringified during construction, and embedded CDATA terminators are split safely.
      #   @param content [Object] wrapped content
      #   @return [Sevgi::Graphics::Content::CData]
      #   @raise [Sevgi::ArgumentError] when content cannot be stringified, contains invalid encoding or illegal XML 1.0
      #     characters, contains cycles, or has keys that collide after stringification
      def self.cdata(...) = CData.send(:new, ...)

      # @overload css(content)
      #   Builds CSS content.
      #   @param content [Hash] CSS rules
      #   @return [Sevgi::Graphics::Content::CSS]
      #   @raise [Sevgi::ArgumentError] when content is not a hash, contains a malformed style, cannot be stringified,
      #     contains invalid encoding or illegal XML 1.0 characters, contains cycles, or has keys that collide after
      #     stringification
      def self.css(...) = CSS.send(:new, ...)

      # @overload encoded(content)
      #   Builds XML text-encoded content.
      #   Mutable objects are stringified during construction before XML text escaping.
      #   @param content [Object] wrapped content
      #   @return [Sevgi::Graphics::Content::Encoded]
      #   @raise [Sevgi::ArgumentError] when content cannot be stringified, contains invalid encoding or illegal XML 1.0
      #     characters, contains cycles, or has keys that collide after stringification
      def self.encoded(...) = Encoded.send(:new, ...)

      # @overload verbatim(content)
      #   Builds verbatim content.
      #   Mutable objects are stringified during construction.
      #   @param content [Object] wrapped content
      #   @return [Sevgi::Graphics::Content::Verbatim]
      #   @raise [Sevgi::ArgumentError] when content cannot be stringified, contains invalid encoding or illegal XML 1.0
      #     characters, contains cycles, or has keys that collide after stringification
      def self.verbatim(...) = Verbatim.send(:new, ...)

      # Returns a recursively independent, caller-owned payload snapshot.
      # @return [Object] wrapped content snapshot
      def content = Snapshot.copy(@content)

      # Creates immutable content from a deep payload snapshot. Strings and containers are copied recursively. Mutable
      # non-container objects are stringified once during construction. The caller's objects are never retained.
      # @param content [Object] wrapped content
      # @return [void]
      # @raise [Sevgi::ArgumentError] when content cannot be stringified, contains invalid encoding or illegal XML
      #   characters, contains cycles, or has keys that collide after stringification
      # @api private
      def initialize(content)
        @content = Snapshot.capture(content, context: "XML content", freeze: true)
        freeze
      end

      # Reports whether the captured payload is empty.
      # @return [Boolean]
      def empty? = payload.respond_to?(:empty?) ? payload.empty? : to_s.empty?

      # Reports strict content equality by concrete class and captured payload.
      # @param other [Object] comparison target
      # @return [Boolean]
      def eql?(other) = self.class == other.class && payload.eql?(other.send(:payload))

      # Returns a hash compatible with strict equality.
      # @return [Integer]
      def hash = [self.class, payload].hash

      alias == eql?

      # Appends this content's serialized XML lines to rendering output.
      # The output collaborator responds to `append(depth, *lines)`, where `depth` is an Integer or nil and every line
      # is a String containing valid serialized XML text. The rendering engine ignores both `append` and `render` return
      # values. Custom content is responsible for escaping data that it inserts into markup.
      # @abstract Subclasses implement content rendering.
      # @param _output [#append] rendering output collaborator
      # @param _depth [Integer] current render depth
      # @return [Object] ignored by the rendering engine
      # @raise [Sevgi::PanicError] when a subclass does not implement render
      def render(_output, _depth) = PanicError.("#{self.class}#render must be implemented")

      # Returns content as a string.
      # @return [String]
      def to_s = XML.text(payload)

      private

      def initialize_copy(original)
        super
        freeze
      end

      def payload = @content

      # CDATA section content backed by an immutable payload snapshot. Mutable leaf objects are stringified during
      # construction. Embedded terminators are split during rendering.
      # @see Content.cdata
      class CData < Content
        # Renders CDATA content.
        # Embedded `]]>` terminators are split across adjacent CDATA sections so the output remains valid XML.
        # @param renderer [#append] rendering output collaborator
        # @param depth [Integer] current render depth
        # @return [Object] ignored by the rendering engine
        def render(renderer, depth)
          depth += 1

          renderer.append(depth, "<![CDATA[")
          renderer.append(depth + 1, *Array(payload).map { safe(it) })
          renderer.append(depth, "]]>")
        end

        private

        def safe(value) = XML.cdata(value)
      end

      # CSS content rendered inside a CDATA section. Rules are captured recursively during construction. Mutable
      # selectors, property names, and values are stringified once, and embedded CDATA terminators are split safely.
      # @see Content.css
      class CSS < Content
        # Creates CSS content.
        # @param content [Hash] CSS rules
        # @return [void]
        # @raise [Sevgi::ArgumentError] when content is not a hash, contains a malformed style, cannot be stringified,
        #   contains invalid encoding or illegal XML 1.0 characters, contains cycles, or has keys that collide after
        #   stringification
        # @api private
        def initialize(content)
          ArgumentError.("CSS content must be a hash") unless content.is_a?(::Hash)
          validate_styles(content)

          super
          validate_declarations(payload)
        end

        # Renders CSS content.
        # @param renderer [#append] rendering output collaborator
        # @param depth [Integer] current render depth
        # @return [Object] ignored by the rendering engine
        def render(renderer, depth)
          depth += 1

          renderer.append(depth, "<![CDATA[")

          depth += 1
          payload.each do |rule, styles|
            case styles
            when ::Hash
              renderer.append(depth, safe("#{rule} {"))
              renderer.append(depth + 1, *styles.map { |key, value| safe("#{key}: #{value};") })
              renderer.append(depth, "}")
            when ::String, ::Symbol, ::Numeric
              renderer.append(depth, safe("#{rule}: #{styles};"))
            else
              ArgumentError.("Malformed style: #{styles}")
            end
          end

          depth -= 1

          renderer.append(depth, "]]>")
        end

        private

        def safe(value) = XML.cdata(value)

        def validate_styles(content)
          content.each_value do |styles|
            next if styles.is_a?(::Hash) || scalar_value?(styles)

            ArgumentError.("Malformed style type: #{styles.class}")
          end
        end

        def validate_declarations(content)
          content.each_value do |styles|
            next unless styles.is_a?(::Hash)

            styles.each_value do |value|
              next if scalar_value?(value)

              ArgumentError.("Malformed style value: #{value.inspect}")
            end
          end
        end

        def scalar_value?(value) = value.is_a?(::String) || value.is_a?(::Symbol) || finite_real?(value)

        def finite_real?(value) = value.is_a?(::Numeric) && !value.is_a?(::Complex) && value.finite?
      end

      # XML text-encoded content backed by an immutable payload snapshot. Mutable leaf objects are stringified during
      # construction, before XML escaping.
      # @see Content.encoded
      class Encoded < Content
        # Returns XML text-encoded content.
        # @return [String]
        def to_s = XML.text(payload).encode(xml: :text).gsub("\r", "&#13;")

        # Renders encoded text content.
        # @param renderer [#append] rendering output collaborator
        # @param depth [Integer] current render depth
        # @return [Object] ignored by the rendering engine
        def render(renderer, depth) = renderer.append(depth + 1, to_s)
      end

      # Verbatim content backed by an immutable payload snapshot. Mutable leaf objects are stringified during
      # construction. Verbatim content bypasses XML escaping. Validation guarantees encoding and legal XML 1.0 code
      # points, not well-formed markup supplied by the caller.
      # @see Content.verbatim
      class Verbatim < Content
        # Returns validated verbatim content.
        # @return [String]
        def to_s = XML.text(payload)

        # Renders verbatim content.
        # @param renderer [#append] rendering output collaborator
        # @param depth [Integer] current render depth
        # @return [Object] ignored by the rendering engine
        def render(renderer, depth) = renderer.append(depth + 1, to_s)
      end
    end
  end
end
