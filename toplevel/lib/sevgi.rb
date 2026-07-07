# frozen_string_literal: true

require "sevgi/derender"
require "sevgi/function"
require "sevgi/geometry"
require "sevgi/graphics"
require "sevgi/standard"
require "sevgi/sundries"

require "sevgi/version"

# Minimal top-level SVG interface installed by `require "sevgi"`.
# @return [Module] the graphics module used as the SVG DSL namespace
SVG = Sevgi::Graphics

# @overload SVG(document = :default, canvas = Undefined, **attributes, &block)
#   Builds an SVG document through the default top-level DSL entrypoint.
#   @param document [Symbol, Class] document profile name or document class
#   @param canvas [Object] optional canvas or paper profile argument
#   @param attributes [Hash] root SVG attributes
#   @yield the document block evaluated in the SVG document context
#   @yieldreturn [void]
#   @return [Sevgi::Graphics::Document::Proto] a rendered SVG document object
#   @raise [Sevgi::ArgumentError] when the document, paper, or canvas arguments are invalid
def SVG(...) = Sevgi::Graphics.SVG(...)

# Full top-level API for Sevgi library and script consumers.
#
# Including or extending this module installs DSL methods such as `Paper`, `Load`,
# and `Grid`, plus convenience constants such as `F`, `Geometry`, `Origin`, and
# `Export`.
#
# @example Include the DSL in an object
#   class Drawing
#     include Sevgi
#   end
module Sevgi
  # See sevgi/toplevel/*.rb files for details
  require_relative "sevgi/toplevel"

  # Installs the full toplevel DSL into an including class or module.
  # @param base [Module] the class or module receiving the DSL methods
  # @return [void]
  # @api private
  def self.included(base)
    super
    base.include(Toplevel)
  end

  # Installs the full toplevel DSL into an extending object or module.
  # @param base [Object] the receiver extended with the DSL methods
  # @return [void]
  # @api private
  def self.extended(base)
    super
    base.extend(Toplevel)
  end
end
