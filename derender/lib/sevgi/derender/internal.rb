# frozen_string_literal: true

require "sevgi/function"

module Sevgi
  module Derender
    # CSS parser and formatter helpers used while derendering attributes and style nodes.
    # @api private
    module Css
      require "css_parser"

      # Parses CSS rules into a selector/declaration hash.
      # @param css_string [String] CSS rule source
      # @return [Hash, nil] parsed CSS declarations grouped by selector
      def to_h(css_string)
        parser = ::CssParser::Parser.new
        parser.load_string!(css_string)
        parser.to_h["all"]
      end

      # Parses an inline style declaration string.
      # @param style_string [String] CSS declaration source
      # @return [Hash] parsed declarations for the synthetic universal selector
      def to_h!(style_string)
        hash = to_h("* { #{style_string} }")

        hash ? hash.fetch("*", {}) : {}
      end

      # Converts a CSS key into a Ruby hash key.
      # @param arg [String] CSS key
      # @return [String] Ruby hash key source
      def to_key(arg) = arg

      # Converts a CSS key/value pair into Ruby hash source.
      # @param key [String] CSS declaration key
      # @param value [String] CSS declaration value
      # @return [String] Ruby hash pair source
      def to_key_value(key, value) = "#{Ruby.literal(to_key(key))}: #{to_value(value)}"

      # Converts a CSS value into Ruby source.
      # @param arg [String] CSS value
      # @return [String] Ruby literal or numeric source
      def to_value(arg) = (arg.to_f.to_s == arg) || (arg.to_i.to_s == arg) ? arg : arg.inspect

      extend self
    end

    private_constant :Css

    # Ruby source formatting helpers used by the derender pipeline.
    # @api private
    module Ruby
      require "rufo"

      IDENTIFIER = /\A[a-z][a-zA-Z0-9]*\z/
      KEYWORDS = %w[
        BEGIN
        END
        alias
        and
        begin
        break
        case
        class
        def
        defined
        do
        else
        elsif
        end
        ensure
        false
        for
        if
        in
        module
        next
        nil
        not
        or
        redo
        rescue
        retry
        return
        self
        super
        then
        true
        undef
        unless
        until
        when
        while
        yield
      ]
        .freeze

      private_constant :IDENTIFIER, :KEYWORDS

      # Reports whether an XML element name can be emitted as a bare DSL call.
      # @param name [String] XML element name
      # @return [Boolean]
      def bare_element?(name)
        require "sevgi/graphics" unless defined?(Graphics::Element)

        name = name.to_s

        IDENTIFIER.match?(name) &&
          !name.include?("_") &&
          !KEYWORDS.include?(name) &&
          Graphics::Element.valid?(name.to_sym) &&
          !receiver_collision?(name.to_sym)
      rescue ::Sevgi::ArgumentError
        false
      end

      # Formats generated Ruby source.
      # @param unformatted_ruby [String] unformatted Ruby source
      # @return [String] formatted Ruby source
      # @raise [Sevgi::PanicError] when source cannot be parsed by the formatter
      def format(unformatted_ruby)
        Rufo::Formatter.format(unformatted_ruby)
      rescue Rufo::SyntaxError
        PanicError.(unformatted_ruby)
      end

      # Converts a value into a Ruby string literal.
      # @param value [Object] value to stringify
      # @return [String] Ruby string literal source
      def literal(value) = value.to_s.inspect

      private

      def receiver_collision?(name)
        document = Graphics::Document.const_get(:Base, false)

        document.ancestors.any? do |ancestor|
          ancestor.method_defined?(name, false) || ancestor.private_method_defined?(name, false)
        end
      end

      extend self
    end

    private_constant :Ruby
  end
end
