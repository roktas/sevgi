# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    class EllipseTest < Minitest::Test
      def test_construction_preserves_canonical_fields
        ellipse = Ellipse[4, 2, position: [10, 20], rotation: 450]

        assert_kind_of(Element::Arced, ellipse)
        assert_raises(NoMethodError) { Element::Arced.new }
        [
          Point[10, 20],
          ellipse.position,
          ellipse.position,
          ellipse.center,
          4.0,
          ellipse.rx,
          2.0,
          ellipse.ry,
          450.0,
          ellipse.rotation,
          Point[10, 24],
          ellipse.point(0).approx,
          Point[8, 20],
          ellipse.point(90).approx
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        refute(ellipse.circular?)
        refute(ellipse.empty?)
        assert(ellipse.equations.frozen?)
      end

      def test_construction_rejects_invalid_geometry
        [0, -1, Float::INFINITY, Float::NAN, Complex(1, 1), "2", nil].each do |value|
          assert_raises(Error) { Ellipse[value, 2] }
          assert_raises(Error) { Ellipse[2, value] }
          assert_raises(Error) { Circle[value] }
        end

        assert_raises(Error) { Ellipse[2, 1, rotation: Float::INFINITY] }
        assert_raises(Error) { Ellipse[2, 1, position: [0, Float::NAN]] }
      end

      def test_box_uses_rotated_extrema_without_rounding
        ellipse = Ellipse[4, 2, position: [10, 20], rotation: 45]
        box = ellipse.box
        assert_in_delta(2 * Math.sqrt(10), box.width, 1e-12)
        assert_in_delta(2 * Math.sqrt(10), box.height, 1e-12)
        assert_in_delta(10 - Math.sqrt(10), box.position.x, 1e-12)
        F.with_precision(0) { assert_equal(box, ellipse.box) }
      end

      def test_membership_uses_world_coordinate_precision
        ellipse = Ellipse[4, 2, position: [10, 20], rotation: 30]
        assert(ellipse.inside?(ellipse.center))
        refute(ellipse.on?(ellipse.center))
        assert(ellipse.on?(ellipse.point(73)))
        assert(ellipse.outside?([30, 30]))

        F.with_precision(4) do
          circle = Circle[1e8]
          refute(circle.on?([1e8 + 0.01, 0]))
          assert(circle.outside?([1e8 + 0.01, 0]))
        end
      end

      def test_approx_and_equality_preserve_canonical_state
        ellipse = Ellipse[2.345, 1.234, position: [3.456, 4.567], rotation: 12.345]
        rounded = ellipse.approx(2)
        assert_equal(Ellipse[2.35, 1.23, position: [3.46, 4.57], rotation: 12.35], rounded)
        assert_equal(rounded, rounded.approx(2))
        assert_equal(2.345, ellipse.rx)
        assert(ellipse.eq?(rounded, precision: 2))
        refute_equal(ellipse, rounded)
        refute_equal(Ellipse[2, 2], Circle[2])
        assert_raises(Error) { Ellipse[0.001, 1].approx(2) }
        assert(Ellipse[0.001, 1].eq?(Ellipse[0.002, 1], precision: 2))
        hash = ellipse.hash
        F.with_precision(0) do
          assert_equal(hash, ellipse.hash)
          assert_equal(ellipse, Ellipse[2.345, 1.234, position: [3.456, 4.567], rotation: 12.345])
        end
      end

      def test_circle_preserves_or_widens_its_semantic_class
        circle = Circle[3, position: [1, 2]]
        assert_equal(3.0, circle.radius)
        assert(circle.circular?)
        [circle.rotate(30), circle.scale(-2), circle.reflect(x: true, y: false), circle.translate(2)].each do |value|
          assert_instance_of(Circle, value)
        end

        assert_instance_of(Ellipse, circle.scale(2, 1))
        assert_instance_of(Ellipse, circle.skew_x(30))
        assert_instance_of(Ellipse, circle.arc(extent: 90).ellipse)
      end

      def test_length_uses_independent_numerical_accuracy
        # Complete elliptic integral of the second kind: 8 E(3/4).
        expected = 9.688448220547676
        [0, 3, 10].each do |precision|
          F.with_precision(precision) { assert_in_delta(expected, Ellipse[2, 1].length, 1e-9) }
        end

        circle = Circle[3]
        assert_in_delta(6 * Math::PI, circle.length, 1e-12)
        assert_equal(circle.length, circle.perimeter)
      end

      def test_sweep_and_alignment_use_closed_boundary
        ellipse = Ellipse[5, 3]
        lines = Operation.sweep(ellipse, initial: Origin, angle: 0, step: 3)
        assert_equal(1, lines.size)
        assert_equal(10.0, lines.first.length)
        [ellipse, Circle[3], ellipse.arc(extent: 90)].each do |element|
          aligned = Operation.align(element, Rect[20, 10], :right)
          assert_in_delta(20, aligned.box.position.x + aligned.box.width, 1e-10)
        end
      end
    end
  end
end
