# frozen_string_literal: true

module Sevgi
  module Graphics
    # XML 1.0 text and qualified-name validation shared by renderer boundaries.
    # @api private
    module XML
      NCNAME_START = "A-Z_a-z\u{C0}-\u{D6}\u{D8}-\u{F6}\u{F8}-\u{2FF}\u{370}-\u{37D}\u{37F}-\u{1FFF}" \
        "\u{200C}-\u{200D}\u{2070}-\u{218F}\u{2C00}-\u{2FEF}\u{3001}-\u{D7FF}\u{F900}-\u{FDCF}" \
        "\u{FDF0}-\u{FFFD}\u{10000}-\u{EFFFF}"
      NCNAME_CHAR = "#{NCNAME_START}\\-.0-9\u{B7}\u{300}-\u{36F}\u{203F}-\u{2040}".freeze
      NCNAME = "[#{NCNAME_START}][#{NCNAME_CHAR}]*".freeze
      QNAME = /\A#{NCNAME}(?::#{NCNAME})?\z/u

      private_constant :NCNAME, :NCNAME_CHAR, :NCNAME_START, :QNAME

      class << self
        # Validates an XML 1.0 string representation.
        # @param value [Object] value to stringify and validate
        # @param context [String] error-message subject
        # @return [String] UTF-8 text
        # @raise [Sevgi::ArgumentError] when stringification, encoding, or XML character validation fails
        def text(value, context: "XML content")
          value = stringify(value, context:) unless value.is_a?(::String)
          validate_string(value, context:)
        end

        # Validates and snapshots a nested XML-bound value.
        # @param value [Object] scalar or nested container
        # @param context [String] error-message subject
        # @param seen [Hash] container identities on the current traversal path
        # @return [Object] validated caller-owned snapshot
        # @raise [Sevgi::ArgumentError] when the value is cyclic, collides after stringification, or has invalid XML text
        def snapshot(value, context:, seen: {}.compare_by_identity)
          case value
          when ::Hash
            nested(value, context:, seen:) { snapshot_hash(value, context:, seen:) }
          when ::Array
            nested(value, context:, seen:) { value.map { snapshot(it, context:, seen:) } }
          else
            text(value, context:)
          end
        end

        # Validates an XML qualified name.
        # @param value [Object] candidate name
        # @param context [String] error-message subject
        # @return [String] validated qualified name
        # @raise [Sevgi::ArgumentError] when text conversion or QName validation fails
        def name(value, context: "XML name")
          text(value, context:).tap do |candidate|
            ArgumentError.("#{context} is invalid: #{candidate.inspect}") unless QNAME.match?(candidate)
          end
        end

        # Validates a nested XML value without retaining its snapshot.
        # @param value [Object] scalar or nested container
        # @param context [String] error-message subject
        # @return [Object] original value
        # @raise [Sevgi::ArgumentError] when nested content is cyclic or contains invalid XML text
        def validate(value, context: "XML content")
          snapshot(value, context:)
          value
        end

        # Escapes embedded CDATA terminators after validating text.
        # @param value [Object] CDATA value
        # @return [String] safe CDATA body
        # @raise [Sevgi::ArgumentError] when value is not valid XML text
        def cdata(value) = text(value).gsub("]]>", "]]]]><![CDATA[>")

        private

        def nested(value, context:, seen:)
          ArgumentError.("Cyclic #{context} is not supported") if seen.key?(value)

          seen[value] = true
          yield
        ensure
          seen.delete(value)
        end

        def snapshot_hash(value, context:, seen:)
          value.each_with_object({}) do |(key, item), captured|
            key = snapshot(key, context:, seen:)
            ArgumentError.("#{context} keys collide after stringification") if captured.key?(key)

            captured[key] = snapshot(item, context:, seen:)
          end
        end

        def stringify(value, context:)
          text = value.to_s
          ArgumentError.("#{context} stringification must return a String") unless text.is_a?(::String)

          text
        rescue Sevgi::ArgumentError
          raise
        rescue ::StandardError => e
          ArgumentError.("#{context} cannot be stringified: #{e.class}: #{e.message}")
        end

        def validate_string(value, context:)
          ArgumentError.("#{context} must be valid UTF-8") unless value.valid_encoding?

          text = value.encode("UTF-8")
          if (codepoint = text.each_codepoint.find { !legal_codepoint?(it) })
            ArgumentError.("#{context} contains illegal character U+#{format("%04X", codepoint)}")
          end

          text
        rescue ::EncodingError => e
          ArgumentError.("#{context} must be valid UTF-8: #{e.message}")
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
  end
end
