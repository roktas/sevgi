# frozen_string_literal: true

module Sevgi
  # Shared implementation for the full Sevgi top-level DSL.
  #
  # This module is installed by `include Sevgi` or `extend Sevgi`; it should not
  # normally be included directly.
  #
  # @see Sevgi
  module Toplevel
    @constants = {}

    class << self
      # Returns an immutable snapshot of promoted constants.
      # @return [Hash<Symbol, Object>]
      def constants = @constants.dup.freeze

      private

      def inject(base)
        return if base.instance_variable_defined?("@_toplevel_injected_")

        if base.is_a?(::Module)
          @constants.each do |name, constant|
            base.const_set(name, constant) unless base.const_defined?(name, false)
          end
        end

        base.instance_variable_set("@_toplevel_injected_", true)
      end

      def promote(constant, symbol = Undefined)
        @constants[Undefined.default(symbol, constant.to_s.split("::").last.to_sym)] = constant
      end
    end

    # Injects promoted constants when the DSL is included in a module or class.
    # @param base [Module] the class or module receiving promoted constants
    # @return [void]
    # @api private
    def self.included(base)
      super
      inject(base)
    end

    # Injects promoted constants when the DSL is extended by a module.
    # @param base [Object] the object or module receiving the DSL methods
    # @return [void]
    # @note Constants are promoted only to modules/classes. Extending an ordinary object installs methods without
    #   writing constants to `Object`.
    # @api private
    def self.extended(base)
      super
      inject(base)
    end
  end

  extend Toplevel
end

require_relative "toplevel/derender"
require_relative "toplevel/executor"
require_relative "toplevel/function"
require_relative "toplevel/geometry"
require_relative "toplevel/graphics"
require_relative "toplevel/sundries"
