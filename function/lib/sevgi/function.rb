# frozen_string_literal: true

require_relative "core"

require_relative "function/color"
require_relative "function/file"
require_relative "function/locate"
require_relative "function/math"
require_relative "function/shell"
require_relative "function/string"
require_relative "function/ui"

require_relative "function/version"

module Sevgi
  # Shared helper namespace used directly as `Sevgi::Function` and through {Sevgi::F}.
  #
  # @example Use helper methods through the public alias
  #   F.pluralize("axis")
  module Function
  end

  # Public alias for the shared function helper namespace.
  F = Function unless defined?(F)
end
