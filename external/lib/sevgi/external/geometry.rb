# frozen_string_literal: true

require "sevgi/geometry"

module Sevgi
  module External
    Promote Geometry
    Promote Geometry::Origin, :Origin
  end
end
