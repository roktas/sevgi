# frozen_string_literal: true

require_relative "function/color"
require_relative "function/file"
require_relative "function/math"
require_relative "function/pluralize"
require_relative "function/shell"
require_relative "function/string"
require_relative "function/ui"

module Sevgi
  class Error < StandardError
    def self.call(...) = raise(self, ...)
  end unless defined?(Error)

  ArgumentError = Class.new(Error) unless defined?(self::ArgumentError)

  # Copied from https://github.com/dry-rb/dry-core. All kudos to the original authors.

  EMPTY_ARRAY  = [].freeze
  EMPTY_HASH   = {}.freeze
  EMPTY_OPTS   = {}.freeze
  EMPTY_STRING = ""
  IDENTITY     = (->(x) { x }).freeze
  F            = Function unless defined?(F)

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
end
