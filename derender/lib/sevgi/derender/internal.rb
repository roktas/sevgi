# frozen_string_literal: true

require "sevgi/function"

module Sevgi
  module Function
    module CSS
      require "css_parser"

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
      require "rufo"

      def ruby(unformatted_ruby)
        Rufo::Formatter.format(unformatted_ruby)
      rescue Rufo::SyntaxError
        raise unformatted_ruby
      end
    end

    extend Ruby
  end
end
