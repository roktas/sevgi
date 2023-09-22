# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    module Equation
      module Line
        class HorizontalTest < Minitest::Test
          include Fixtures

          def test_fixtures_construction
            hline4
          end

          def test_horizontal
            assert_in_delta(1.0, Line.horizontal(1.0).y(1))
          end
        end
      end
    end
  end
end
