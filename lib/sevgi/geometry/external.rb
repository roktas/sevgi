# frozen_string_literal: true

module Sevgi
  module Geometry
    module External
      class << self
        def included(base)
          super

          base.const_set(:Geometry, Geometry)
        end
      end
    end
  end
end
