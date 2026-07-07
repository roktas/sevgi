# frozen_string_literal: true

require "sevgi/function"

module Sevgi
  module Toplevel
    # Function helper namespace promoted as `F` by the full top-level DSL.
    #
    # @example Use helper functions inside script mode
    #   SVG do
    #     text F.pluralize("axis")
    #   end
    module Function
      extend Sevgi::Function::Color
      extend Sevgi::Function::Math
      extend Sevgi::Function::Pluralize
      extend Sevgi::Function::Shell
      extend Sevgi::Function::UI
    end

    promote Function, :F
  end
end
