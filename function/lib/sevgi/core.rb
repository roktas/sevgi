# frozen_string_literal: true

module Sevgi
  # Constants
  ENVVOMIT = "SEVGI_VOMIT"
  EXTENSION = "sevgi"

  # Errors
  unless defined?(Error)
    class Error < StandardError
      def self.call(*, **, &) = raise(self, *, **, &)
    end
  end

  # for missing optional components
  unless defined?(self::MissingComponentError)
    class MissingComponentError < Error
      attr_reader :component

      def initialize(component)
        @component = component.to_s

        super("\"#{component}\" required")
      end
    end
  end

  # for internal invariants and implementation bugs
  PanicError = Class.new(Error) unless defined?(self::PanicError)

  # for incorrect API usage
  ArgumentError = Class.new(Error) unless defined?(self::ArgumentError)

  # Helpers
  # Copied from https://github.com/dry-rb/dry-core. All kudos to the original authors.
  EMPTY_ARRAY = [].freeze
  EMPTY_HASH = {}.freeze
  EMPTY_OPTS = {}.freeze
  EMPTY_STRING = ""
  IDENTITY = -> (x) { x }.freeze

  Undefined = Object
    .new
    .tap do |undefined|
      const_set(:Self, -> { Undefined })

      def undefined.to_s = "Undefined"

      def undefined.inspect = "Undefined"

      def undefined.default(x, y = self)
        return x unless equal?(x)

        equal?(y) ? yield : y
      end

      def undefined.map(value) = equal?(value) ? self : yield(value)

      def undefined.dup = self

      def undefined.clone = self

      def undefined.coalesce(*args) = args.find(Self) { |x| !equal?(x) }
    end
    .freeze
end
