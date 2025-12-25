# frozen_string_literal: true

require "sevgi/derender"
require "sevgi/function"
require "sevgi/geometry"
require "sevgi/graphics"
require "sevgi/standard"
require "sevgi/sundries"
require "sevgi/version"

# Minimal Toplevel Interface (activated with 'require "sevgi"')
def SVG(...) = ::Sevgi::Graphics.SVG(...)

# Maximal Toplevel Interface (activated with 'include Sevgi')
module Sevgi
  # See sevgi/toplevel/*.rb files for details
  require_relative "sevgi/toplevel"

  def self.included(base) = (super; base.include(Toplevel))

  def self.extended(base) = (super; base.extend(Toplevel))
end
