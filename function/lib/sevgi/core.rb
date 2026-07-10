# frozen_string_literal: true

module Sevgi
  # Environment variable that asks command-line tools to re-raise captured errors.
  ENVVOMIT = "SEVGI_VOMIT"

  # Default file extension for Sevgi scripts.
  EXTENSION = "sevgi"

  unless defined?(Error)
    # Base error class for Sevgi failures.
    class Error < StandardError
      # @overload call(*args, **kwargs, &block)
      #   Raises this error class.
      #   @param args [Array] positional arguments forwarded to the exception constructor
      #   @param kwargs [Hash] keyword arguments forwarded to the exception constructor
      #   @yield optional block forwarded to the exception constructor
      #   @yieldreturn [Object]
      #   @return [void]
      #   @raise [Sevgi::Error] always raises an instance of this class
      def self.call(*, **, &) = raise(self, *, **, &)
    end
  end

  unless defined?(self::MissingComponentError)
    # Error raised when an optional Sevgi component is required but unavailable.
    class MissingComponentError < Error
      # @return [String] missing component name
      attr_reader :component

      # Builds a missing component error.
      # @param component [String, Symbol] missing component name
      # @return [void]
      def initialize(component)
        @component = component.to_s

        super("\"#{component}\" required")
      end
    end
  end

  # Error raised for internal invariants and implementation paths that should be unreachable.
  PanicError = Class.new(Error) unless defined?(self::PanicError)

  # Error raised for invalid public API usage.
  ArgumentError = Class.new(Error) unless defined?(self::ArgumentError)

  # Sentinel object used to distinguish an omitted value from nil.
  Undefined = Object
    .new
    .tap do |undefined|
      const_set(:Self, -> { Undefined })

      # Returns the sentinel name.
      # @return [String]
      def undefined.to_s = "Undefined"

      # Returns the sentinel inspection string.
      # @return [String]
      def undefined.inspect = "Undefined"

      # Resolves a value unless it is {Sevgi::Undefined}.
      # @param x [Object] candidate value
      # @param y [Object] fallback value
      # @yield computes the fallback when both x and y are undefined
      # @yieldreturn [Object]
      # @return [Object] x, y, or the yielded fallback
      def undefined.default(x, y = self)
        return x unless equal?(x)

        equal?(y) ? yield : y
      end

      # Maps a value unless it is {Sevgi::Undefined}.
      # @param value [Object] candidate value
      # @yield maps a defined value
      # @yieldparam value [Object] the defined value
      # @yieldreturn [Object]
      # @return [Object] the sentinel or the mapped value
      def undefined.map(value) = equal?(value) ? self : yield(value)

      # Returns the sentinel itself.
      # @return [Sevgi::Undefined]
      def undefined.dup = self

      # Returns the sentinel itself.
      # @return [Sevgi::Undefined]
      def undefined.clone = self

      # Returns the first argument that is not {Sevgi::Undefined}.
      # @param args [Array<Object>] candidate values
      # @return [Object, nil] first defined value, including nil, or nil when none exists
      # @example Resolve an optional value
      #   Sevgi::Undefined.coalesce(Sevgi::Undefined, nil) # => nil
      # @see #default
      def undefined.coalesce(*args) = args.find { |x| !equal?(x) }
    end
    .freeze
end
