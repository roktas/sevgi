# frozen_string_literal: true

require_relative "core"

require_relative "function/color"
require_relative "function/file"
require_relative "function/locate"
require_relative "function/math"
require_relative "function/shell"
require_relative "function/string"
require_relative "function/ui"

module Sevgi
  F = Function unless defined?(F)
end
