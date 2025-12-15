# frozen_string_literal: true

module Sevgi
  module Derender
    module Attribute
      def self.render(*hashes) = hashes.map { hash_to_string(it) }.reject(&:empty?).join(", ")

      def self.pair(key, value) = "\"#{to_key(key)}\": #{to_value(value)}"

      class << self
        private

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

          def hash_to_string(hash)
            pre, post = {}, {}

            ATTRIBUTES_SHOULD_COME_FIRST.each { |key| pre[key]  = hash.delete(key) if hash.key?(key) }
            ATTRIBUTES_SHOULD_COME_LAST.each  { |key| post[key] = hash.delete(key) if hash.key?(key) }

            { **pre, **hash, **post }.map do |key, value|
              key = to_key(key) if key.is_a?(::String)

              if key == "style"
                "{ #{render(style_to_hash(value))} }"
              elsif value.is_a?(::String)
                to_value(value)
              elsif value.is_a?(::Hash)
                "{ #{render(value)} }"
              else
                value
              end => value

              key.match?(/\W/) ? "\"#{key}\": #{value}" : "#{key}: #{value}"
            end.join(", ")
          end

          # Transforms the values of a style attribute to a hash
          # Example: "color: black; top: 10" => { color: black, top: 10 }
          def style_to_hash(string)
            parser = CssParser::Parser.new
            parser.load_string! "* { #{string} }"
            parser.to_h["all"]["*"]
          end

          def to_key(arg)   = arg

          def to_value(arg) = (arg.to_f.to_s == arg) || (arg.to_i.to_s == arg) ? arg : %("#{arg}")
      end
    end
  end
end
