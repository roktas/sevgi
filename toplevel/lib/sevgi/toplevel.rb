# frozen_string_literal: true

module Sevgi
  module Toplevel
    @constants = {}

    class << self
      attr_reader :constants

      private

        def Promote(constant, symbol = Undefined)
          @constants[Undefined.default(symbol, constant.to_s.split("::").last.to_sym)] = constant
        end

        def inject(base)
          return if base.instance_variable_defined?("@_toplevel_injected_")

          @constants.each { |args| (base.is_a?(::Module) ? base : base.class).const_set(*args) }
          base.instance_variable_set("@_toplevel_injected_", true)
        end
    end

    def self.included(base) = (super; inject(base))

    def self.extended(base) = (super; inject(base))
  end

  extend Toplevel
end

require_relative "toplevel/derender"
require_relative "toplevel/executor"
require_relative "toplevel/function"
require_relative "toplevel/geometry"
require_relative "toplevel/graphics"
require_relative "toplevel/sundries"
