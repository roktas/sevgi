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

          def LineTo(**attributes) = (@lines ||= []) << attributes
        end

        def test_hatch_draws_swept_lines
          node = Node.new

          node.Hatch(Geometry::Rect[2, 4], angle: 45.0, step: ::Math.sqrt(2.0), class: %w[smoke hatch])

          assert_equal(
            [
              {x1: 2.0, y1: 4.0, x2: 0.0, y2: 2.0, class: %w[smoke hatch]},
              {x1: 0.0, y1: 0.0, x2: 2.0, y2: 2.0, class: %w[smoke hatch]}
            ],
            node.lines
          )
        end

        def test_hatch_preserves_geometry_error_channels
          node = Node.new

          assert_raises(Geometry::Operation::OperationInapplicableError) do
            node.Hatch(Object.new, angle: 0, step: 1)
          end

          assert_raises(Geometry::Error) do
            node.Hatch(Geometry::Rect[2, 4], angle: 0, step: 0)
          end

          assert_raises(Geometry::Operation::OperationError) do
            node.Hatch(Geometry::Polyline.([0, 0], [1, 0]), angle: 0, step: 1)
          end
        end

        def test_hatch_can_extend_a_scoped_minimal_profile
          profile = Class.new(Document::Minimal)
          Mixtures.mixin(:Hatch, profile)
          drawn = nil
          hatched = nil

          drawing = Graphics.SVG(profile) do
            region = Geometry::Rect[2, 2]
            drawn = Draw(region.lines)
            hatched = Hatch(region, angle: 0, step: 1)
          end

          assert_equal(4, drawn.size)
          refute_empty(hatched)
          assert(drawing.children.all? { it.name == :path })
          refute_includes(drawing.Render(), "inkscape")
        end
      end
    end
  end
end
