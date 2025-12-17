# frozen_string_literal: true

module Sevgi
  module Derender
    module Attributes
      ATTRIBUTES_SHOULD_COME_FIRST = %w[
        id
        inkscape:label
        class
        xmlns
        xmlns:svg
        xmlns:inkscape
        xmlns:sodipodi
        xmlns:_
      ].freeze
      ATTRIBUTES_SHOULD_COME_LAST  = %w[
        style
      ].freeze

      def compile(hash)
        pre, post = {}, {}

        ATTRIBUTES_SHOULD_COME_FIRST.each { |key| pre[key]  = hash.delete(key) if hash.key?(key) }
        ATTRIBUTES_SHOULD_COME_LAST.each  { |key| post[key] = hash.delete(key) if hash.key?(key) }

        { **pre, **hash, **post }.map do |key, value|
          key = Css.to_key(key) if key.is_a?(::String)

          if key == "style"
            "{ #{Attributes.compile(Css.to_h!(value))} }"
          elsif value.is_a?(::String)
            Css.to_value(value)
          elsif value.is_a?(::Hash)
            "{ #{Attributes.compile(value)} }"
          else
            value
          end => value

          key.match?(/\W/) ? "\"#{key}\": #{value}" : "#{key}: #{value}"
        end.join(", ")
      end

      extend self
    end
  end
end
