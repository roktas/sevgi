# frozen_string_literal: true

require "sevgi/geometry"

module Sevgi
  module Toplevel
    Promote Geometry
    Promote Geometry::Origin, :Origin
  end
end
