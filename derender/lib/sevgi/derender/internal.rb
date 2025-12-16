# frozen_string_literal: true

require "css_parser"
require "rufo"

module Sevgi
  module Derender
    module CSS
      def to_hash(css_string)
        parser = CssParser::Parser.new
        parser.load_string!(css_string)
        parser.to_h["all"]
      end

      def style_to_hash(style_string)
        to_hash("* { #{style_string} }")["*"]
      end

      extend self
    end

    module Ruby
      def call(unformatted_ruby)
        Rufo::Formatter.format(unformatted_ruby)
      rescue Rufo::SyntaxError
        raise unformatted_ruby
      end

      extend self
    end
  end
end
