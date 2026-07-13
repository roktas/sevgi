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
    #   SVG(:minimal) { text(Emphasis["important & safe"]) }.Render
    class Content
      private_class_method :new

      # Immutable payload capture and caller-owned copy helpers.
      # @api private
      module Snapshot
        SCALARS = [::NilClass, ::TrueClass, ::FalseClass, ::Symbol, ::Integer, ::Float, ::Rational, ::Complex].freeze
        private_constant :SCALARS

        class << self
          def capture(value, seen = {}.compare_by_identity)
            case value
            when ::String
              XML.text(value).freeze
            when ::Hash
              nested(value, seen) { capture_hash(value, seen) }.freeze
            when ::Array
              nested(value, seen) { value.map { capture(it, seen) } }.freeze
            else
              SCALARS.include?(value.class) ? value : stringify(value).freeze
            end
          end

          def copy(value)
            case value
            when ::String
              value.dup
            when ::Hash
              value.to_h { |key, item| [copy(key), copy(item)] }
            when ::Array
              value.map { copy(it) }
            else
              value
            end
          end

          private

          def capture_hash(value, seen)
            value.each_with_object({}) do |(key, item), captured|
              key = capture(key, seen)
              ArgumentError.("XML content keys collide after stringification") if captured.key?(key)

              captured[key] = capture(item, seen)
            end
          end

          def nested(value, seen)
            ArgumentError.("Cyclic XML content is not supported") if seen.key?(value)

            seen[value] = true
            yield
          ensure
            seen.delete(value)
          end

          def stringify(value)
            text = value.to_s
            ArgumentError.("XML content stringification must return a String") unless text.is_a?(::String)

            XML.text(text)
          rescue Sevgi::ArgumentError
            raise
          rescue ::StandardError => e
            ArgumentError.("XML content cannot be stringified: #{e.class}: #{e.message}")
          end
        end
      end

      private_constant :Snapshot

      # Returns a recursively independent, caller-owned payload snapshot.
      # @return [Object] wrapped content snapshot
      def content = Snapshot.copy(@content)

      # Creates immutable content from a deep payload snapshot. Strings and containers are copied recursively; mutable
      # non-container objects are stringified once during construction. The caller's objects are never retained.
      # @param content [Object] wrapped content
      # @return [void]
      # @raise [Sevgi::ArgumentError] when content cannot be stringified, contains invalid encoding or illegal XML
      #   characters, contains cycles, or has keys that collide after stringification
      # @api private
      def initialize(content)
        @content = Snapshot.capture(content)
        XML.validate(@content)
      end

      # Copies content payload ownership for duplicated element trees.
      # @param original [Sevgi::Graphics::Content] source content
      # @return [void]
      # @api private
      def initialize_copy(original)
        @content = Snapshot.capture(original.content)
        super
      end

      private :initialize_copy

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

      def payload = @content

      private :payload

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

      # CDATA section content backed by an immutable payload snapshot. Mutable leaf objects are stringified during
      # construction; embedded terminators are split during rendering.
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

      # CSS content rendered inside a CDATA section. Rules are captured recursively during construction; mutable
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
            next if styles.is_a?(::Hash) || styles.is_a?(::String) || styles.is_a?(::Symbol) || styles.is_a?(::Numeric)

            ArgumentError.("Malformed style type: #{styles.class}")
          end
        end
      end

      # XML text-encoded content backed by an immutable payload snapshot. Mutable leaf objects are stringified during
      # construction, before XML escaping.
      # @see Content.encoded
      class Encoded < Content
        # Returns XML text-encoded content.
        # @return [String]
        def to_s = XML.text(payload).encode(xml: :text)

        # Renders encoded text content.
        # @param renderer [#append] rendering output collaborator
        # @param depth [Integer] current render depth
        # @return [Object] ignored by the rendering engine
        def render(renderer, depth) = renderer.append(depth + 1, to_s)
      end

      # Verbatim content backed by an immutable payload snapshot. Mutable leaf objects are stringified during
      # construction. Verbatim content bypasses XML escaping; validation guarantees encoding and legal XML 1.0 code
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
