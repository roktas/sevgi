# frozen_string_literal: true

module Sevgi
  class Error < StandardError
    class << self
      def call(...) = raise(self, ...)
    end
  end unless defined?(Error)

  ArgumentError = Class.new(Error) unless defined?(self::ArgumentError)

  unless defined?(Wet)
    module Wet
      # Copied from https://github.com/dry-rb/dry-core.  All kudos to the original authors.

      EMPTY_ARRAY  = [].freeze
      EMPTY_HASH   = {}.freeze
      EMPTY_OPTS   = {}.freeze
      EMPTY_STRING = ""
      IDENTITY     = (->(x) { x }).freeze

      Undefined = Object.new.tap do |undefined| # rubocop:disable Metrics/BlockLength
        const_set(:Self, -> { Undefined })

        def undefined.to_s                 = "Undefined"

        def undefined.inspect              = "Undefined"

        def undefined.default(x, y = self) = equal?(x) ? (equal?(y) ? yield : y) : x

        def undefined.map(value)           = equal?(value) ? self : yield(value)

        def undefined.dup                  = self

        def undefined.clone                = self

        def undefined.coalesce(*args)      = args.find(Self) { |x| !equal?(x) }
      end.freeze

      def self.included(base)
        super

        constants.each { |const_name| base.const_set(const_name, const_get(const_name)) }
      end
    end

    include Wet
  end
end
