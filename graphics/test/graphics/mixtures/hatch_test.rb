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

        def test_hatch_defaults_to_ellipse_center
          node = Node.new
          node.Hatch(Geometry::Ellipse[5, 3, position: [10, 20]], angle: 0, step: 3)

          assert_equal([{x1: 5.0, y1: 20.0, x2: 15.0, y2: 20.0}], node.lines)
        end

        def test_draw_preserves_native_arced_geometry
          drawing = Graphics.SVG(:inkscape) do
            Draw(Geometry::Circle[3, position: [10, 20]], id: "circle")
            Draw(Geometry::Ellipse[4, 2, position: [10, 20], rotation: 30], transform: "translate(1 2)")
            Draw(Geometry::Arc[4, 2, extent: -270], id: "arc")
            Draw(Geometry::Arc[4, extent: 0], id: "empty")
          end

          rendered = drawing.Render()

          assert_includes(rendered, "<circle id=\"circle\" cx=\"10.0\" cy=\"20.0\" r=\"3.0\"/>")
          assert_includes(rendered, "transform=\"translate(1 2) rotate(30.0 10.0 20.0)\"")
          assert_includes(rendered, "d=\"M 4 0 A 4 2 0 1 0 0 2\"")
          assert_includes(rendered, "<path id=\"empty\" d=\"\"/>")
        end

        def test_draw_does_not_round_valid_arc_state
          rendered = F.with_precision(0) do
            Graphics
              .SVG(:inkscape) do
                Draw(Geometry::Arc[0.001, extent: 359.999])
              end
              .Render()
          end

          assert_match(/A 0.001 0.001 0 1 1/, rendered)
          refute_includes(rendered, "d=\"\"")
        end

        def test_hatch_can_extend_a_scoped_base_profile
          profile = Class.new(Document::Base)
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
