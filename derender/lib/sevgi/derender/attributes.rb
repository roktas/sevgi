# frozen_string_literal: true

module Sevgi
  module Derender
    # Converts SVG/XML attribute hashes into Sevgi DSL keyword source.
    # @api private
    module Attributes
      # Attribute keys rendered before ordinary attributes.
      ATTRIBUTES_SHOULD_COME_FIRST = %w[
        id
        inkscape:label
        class
        xmlns
        xmlns:svg
        xmlns:inkscape
        xmlns:sodipodi
        xmlns:_
      ]
        .freeze

      # Attribute keys rendered after ordinary attributes.
      ATTRIBUTES_SHOULD_COME_LAST = %w[
        style
      ].freeze

      # Converts an attribute hash into Sevgi DSL keyword source.
      # @param hash [Hash{String, Symbol => Object}] attributes to render
      # @return [String] Ruby keyword or hash source
      def decompile(hash)
        hash = hash.dup
        pre, post = {}, {}

        ATTRIBUTES_SHOULD_COME_FIRST.each { |key| pre[key] = hash.delete(key) if hash.key?(key) }
        ATTRIBUTES_SHOULD_COME_LAST.each { |key| post[key] = hash.delete(key) if hash.key?(key) }

        {**pre, **hash, **post}
          .map do |key, value|
            key = Css.to_key(key) if key.is_a?(::String)

            if key == "style"
              style = Css.to_h!(value)
              style.empty? ? "{}" : "{ #{Attributes.decompile(style)} }"
            elsif value.is_a?(::String)
              Css.to_value(value)
            elsif value.is_a?(::Hash)
              "{ #{Attributes.decompile(value)} }"
            else
              value
            end => value

            key.match?(/\W/) ? "#{Ruby.literal(key)}: #{value}" : "#{key}: #{value}"
          end
          .join(", ")
      end

      extend self
    end
  end
end
