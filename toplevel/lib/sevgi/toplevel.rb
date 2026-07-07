# frozen_string_literal: true

module Sevgi
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

    def self.included(base)
      super
      inject(base)
    end

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
