# frozen_string_literal: true

module Sevgi
  module Geometry
    module Element
      class Base
        def at(point = nil, dx: 0, dy: 0) = translate(((point ||= position).x - position.x) + dx, (point.y - position.y) + dy)

        def box                           = raise(NoMethodError, "#{self.class}#box must be implemented")

        def equations                     = raise(NoMethodError, "#{self.class}#equations must be implemented")

        def ignorable?(precision: nil)    = F.zero?(box.width, precision:) && F.zero?(box.height, precision:)

        def position                      = raise(NoMethodError, "#{self.class}#position must be implemented")

        def translate(x, y)               = raise(NoMethodError, "#{self.class}#translate must be implemented")
      end

      require_relative "lined"
      def self.lined(...) = Lined.build(...)

      require_relative "arced"
      def self.arced(...) = Arced.build(...)
    end
  end
end
