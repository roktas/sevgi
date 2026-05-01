# frozen_string_literal: true

require "sevgi/geometry"

module Sevgi
  module Toplevel
    promote Geometry
    promote Geometry::Origin, :Origin
  end
end
