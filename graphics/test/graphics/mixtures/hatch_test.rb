# frozen_string_literal: true

require_relative "../../test_helper"

require "sevgi/geometry"

module Sevgi
  module Graphics
    module Mixtures
      class HatchTest < Minitest::Test
        Node = Class.new do
          include Hatch

          attr_reader :lines

          def Cline(**attributes) = (@lines ||= []) << attributes
        end

        def test_hatch_draws_swept_lines
          node = Node.new

          node.Hatch(Geometry::Rect[2, 4], direction: 45.0, step: ::Math.sqrt(2.0), class: %w[smoke hatch])

          assert_equal(
            [
              {x1: 2.0, y1: 4.0, x2: 0.0, y2: 2.0, class: %w[smoke hatch]},
              {x1: 0.0, y1: 0.0, x2: 2.0, y2: 2.0, class: %w[smoke hatch]}
            ],
            node.lines
          )
        end
      end
    end
  end
end
