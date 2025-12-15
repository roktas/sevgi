# frozen_string_literal: true

require "css_parser"

module Sevgi
  module Derender
    module CSS
      def css_to_hash(css_string)
        parser = CssParser::Parser.new
        parser.load_string!(css_string)
        parser.to_h["all"]
      end

      # Transforms the values of a style attribute to a hash
      # Example: "color: black; top: 10" => { color: black, top: 10 }
      def style_to_hash(style_string)
        css_to_hash("* { #{style_string} }").fetch("*")
      end

      extend self
    end
  end
end
