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
      attr_reader :constants

      private

      def inject(base)
        return if base.instance_variable_defined?("@_toplevel_injected_")

        target = base.is_a?(::Module) ? base : base.class
        @constants.each do |name, constant|
          target.const_set(name, constant) unless target.const_defined?(name, false)
        end

        base.instance_variable_set("@_toplevel_injected_", true)
      end

      def promote(constant, symbol = Undefined)
        @constants[Undefined.default(symbol, constant.to_s.split("::").last.to_sym)] = constant
      end
    end

    # Injects promoted constants when the DSL is included.
    # @param base [Module] the class or module receiving promoted constants
    # @return [void]
    # @api private
    def self.included(base)
      super
      inject(base)
    end

    # Injects promoted constants when the DSL is extended.
    # @param base [Object] the object or module receiving promoted constants
    # @return [void]
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
