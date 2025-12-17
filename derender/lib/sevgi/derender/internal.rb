# frozen_string_literal: true

require "sevgi/function"

require "css_parser"
require "rufo"

module Sevgi
  module Function
    module CSS
      def css_to_hash(css_string)
        parser = CssParser::Parser.new
        parser.load_string!(css_string)
        parser.to_h["all"]
      end

      def style_to_hash(style_string)
        css_to_hash("* { #{style_string} }")["*"]
      end
    end

    extend CSS

    module Ruby
      def ruby(unformatted_ruby)
        Rufo::Formatter.format(unformatted_ruby)
      rescue Rufo::SyntaxError
        raise unformatted_ruby
      end
    end

    extend Ruby
  end
end
