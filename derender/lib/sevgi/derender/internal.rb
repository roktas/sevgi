# frozen_string_literal: true

require "sevgi/function"

module Sevgi
  module Derender
    module Css
      require "css_parser"

      def to_h(css_string)
        parser = ::CssParser::Parser.new
        parser.load_string!(css_string)
        parser.to_h["all"]
      end

      def to_h!(style_string) = to_h("* { #{style_string} }")["*"]

      def to_key(arg) = arg

      def to_key_value(key, value) = "#{Ruby.literal(to_key(key))}: #{to_value(value)}"

      def to_value(arg) = (arg.to_f.to_s == arg) || (arg.to_i.to_s == arg) ? arg : arg.inspect

      extend self
    end

    private_constant :Css

    module Ruby
      require "rufo"

      def format(unformatted_ruby)
        Rufo::Formatter.format(unformatted_ruby)
      rescue Rufo::SyntaxError
        PanicError.(unformatted_ruby)
      end

      def literal(value) = value.to_s.inspect

      extend self
    end

    private_constant :Ruby
  end
end
