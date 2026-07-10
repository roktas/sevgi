# frozen_string_literal: true

require "sevgi/function"

module Sevgi
  module Toplevel
    # Promotes the canonical function helper namespace as `F` in the full top-level DSL.
    #
    # @example Use helper functions inside script mode
    #   SVG do
    #     text F.pluralize("axis")
    #   end
    # @see Sevgi::Function
    promote Sevgi::Function, :F
  end
end
