# frozen_string_literal: true

module Sevgi
  module Derender
    module Refinements
      refine Hash do
        def render
          # TODO: Reduce cognitive complexity

          pre, post = {}, {}

          %w[ id inkscape:label ].each do |key|
            pre[key] = self.delete(key) if self.key?(key)
          end

          %w[ style ].each do |key|
            post[key] = self.delete(key) if self.key?(key)
          end

          { **pre, **self, **post }.map do |key, value|
            key = key.to_key if key.is_a? String

            if key == "style"
              value = "{ #{value.style_to_hash.render} }"
            elsif value.is_a? String
              value = value.to_value
            end

            key.match?(/[^a-zA-Z0-9_]/) ? "\"#{key}\": #{value}" : "#{key}: #{value}"
          end.join ", "
        end
      end

      refine String do
        def to_key
          self
          # tr("-", "_").to_sym.inspect[1..]
        end

        def to_value
          (to_f.to_s == self) || (to_i.to_s == self) ? self : %( "#{self}" )
        end

        # Transforms the valus of a style attribute to a hash
        # Example: "color: black; top: 10" => { color: black, top: 10 }
        def style_to_hash
          parser = CssParser::Parser.new
          parser.load_string! "victor { #{self} }"
          parser.to_h["all"]["victor"]
        end
      end
    end
  end
end
