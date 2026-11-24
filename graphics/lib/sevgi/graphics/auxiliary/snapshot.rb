# frozen_string_literal: true

module Sevgi
  module Graphics
    # Recursive ownership capture and copying for XML-bound values.
    # @api private
    module Snapshot
      COLLISIONS = {
        "XML attribute value" => "Attribute keys collide after normalization or stringification",
        "Document profile metadata" => "Document profile metadata keys collide after stringification"
      }.freeze
      SAFE_SCALARS = [::NilClass, ::TrueClass, ::FalseClass, ::Integer, ::Float, ::Rational, ::Complex].freeze

      class << self
        # Captures a recursively independent snapshot of a value.
        # @param value [Object] scalar or nested container
        # @param context [String] error-message subject
        # @param freeze [Boolean] true to freeze captured containers and strings
        # @param normalize_keys [Boolean] true to normalize direct Hash keys to Symbols
        # @return [Object] captured snapshot
        # @raise [Sevgi::ArgumentError] when value is cyclic, invalid XML, collides, or fails conversion
        def capture(value, context: "XML content", freeze: true, normalize_keys: false)
          collision = COLLISIONS.fetch(context) { "#{context} keys collide after stringification" }
          walk(value, {context:, collision:, freeze:, normalize_keys:}, {}.compare_by_identity)
        end

        # Returns a recursively mutable, caller-owned copy of a captured snapshot.
        # @param value [Object] captured value to copy
        # @return [Object] caller-owned copy
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

        def walk(value, options, seen)
          case value
          when ::Hash
            nested(value, options[:context], seen) { capture_hash(value, options, seen) }
          when ::Array
            child_opts = options[:normalize_keys] ? options.merge(normalize_keys: false) : options
            nested(value, options[:context], seen) { freeze_value(value.map { walk(it, child_opts, seen) }, options) }
          else
            capture_leaf(value, options)
          end
        end

        def capture_hash(value, options, seen)
          child = options[:normalize_keys] ? options.merge(normalize_keys: false) : options
          identities = options[:normalize_keys] ? nil : {}
          result = value.each_with_object({}) do |(key, item), captured|
            key = options[:normalize_keys] ? normalize_key(key, options[:context]) : walk(key, child, seen)
            check_collision(captured, identities, key, options)
            captured[key] = walk(item, child, seen)
          end

          freeze_value(result, options)
        end

        def capture_leaf(value, options)
          return value if SAFE_SCALARS.include?(value.class)
          return XML.text(value, context: options[:context]) && value if value.is_a?(::Symbol)

          text = XML.text(value, context: options[:context])
          return text.dup unless options[:freeze]

          text.frozen? ? text : text.dup.freeze
        end

        def check_collision(captured, identities, key, options)
          return ArgumentError.(options[:collision]) if captured.key?(key)
          return if options[:normalize_keys]

          identity = string_identity(key)
          ArgumentError.(options[:collision]) if identities.key?(identity)
          identities[identity] = true
        end

        def freeze_value(value, options) = options[:freeze] ? value.freeze : value

        def nested(value, context, seen)
          ArgumentError.("Cyclic #{context} is not supported") if seen.key?(value)
          seen[value] = true
          yield
        ensure
          seen.delete(value)
        end

        def normalize_key(key, context)
          normalized = key.to_sym if key.respond_to?(:to_sym)
          return XML.text(normalized, context:) && normalized if normalized.is_a?(::Symbol)

          ArgumentError.("Attribute Hash keys must normalize to Symbols")
        rescue Sevgi::ArgumentError
          raise
        rescue ::StandardError => e
          ArgumentError.("Attribute Hash key cannot be normalized: #{e.class}: #{e.message}")
        end

        def string_identity(value)
          case value
          when ::Hash
            value.to_h { |key, item| [string_identity(key), string_identity(item)] }
          when ::Array
            value.map { string_identity(it) }
          when ::String
            value
          else
            value.to_s
          end
        end
      end
    end

    private_constant :Snapshot
  end
end
