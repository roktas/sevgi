# frozen_string_literal: true

module Sevgi
  module Derender
    module Render
      module CSS
        def self.render(hash)
          [
            "{",
            hash.map do |selector, declarations|
              [
                "\"#{selector}\": {",
                *declarations.map { |key, value| "#{Attributes.pair(key, value)}," },
                "},"
              ]
            end,
            "}",
          ].flatten.join("\n")
        end
      end
    end
  end
end
