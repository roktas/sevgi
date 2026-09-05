# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    class ArcTest < Minitest::Test
      def test_construction_shares_the_parent_frame
        ellipse = Ellipse[4, 2, position: [10, 20], rotation: 30]
        arc = ellipse.arc(starting_angle: 450, extent: -120)
        assert_same(ellipse, arc.ellipse)
        assert_same(ellipse.equation, arc.equation)
        assert_equal(Arc[4, 2, position: [10, 20], rotation: 30, starting_angle: 450, extent: -120], arc)
        assert_equal(450.0, arc.starting_angle)
        assert_equal(330.0, arc.ending_angle)
        assert_equal(ellipse.point(450), arc.starting)
        assert_equal(ellipse.point(330), arc.ending)
        assert_equal(ellipse.center, arc.position)
        assert(arc.counterclockwise?)
        refute(arc.clockwise?)
      end

      def test_extent_rejects_full_turns_and_nonfinite_values
        [-720, -360, 360, 720, Float::NAN, Float::INFINITY, "90", nil].each do |extent|
          assert_raises(Error) { Arc[1, extent:] }
        end
      end

      def test_zero_extent_has_a_single_point_trace
        arc = Arc[4, 2, starting_angle: 90, extent: 0]
        assert(arc.empty?)
        refute(arc.clockwise?)
        refute(arc.counterclockwise?)
        assert_equal(0.0, arc.length)
        assert(arc.on?([0, 2]))
        assert(arc.inside?([0, 2]))
        refute(arc.inside?(Origin))
        assert_equal([Point[0, 2]], arc.intersection(Equation.vertical(0)))
        assert_equal(0.0, arc.box.width)
        assert_equal(0.0, arc.box.height)
      end

      def test_membership_filters_directed_wrapped_spans
        [
          [350, 20],
          [10, -20]
        ].each do |starting_angle, extent|
          arc = Arc[4, 2, starting_angle:, extent:]
          assert(arc.on?([4, 0]))
          refute(arc.on?([-4, 0]))
          assert(arc.on?(arc.starting))
          assert(arc.on?(arc.ending))
          assert_equal([Point[4, 0]], arc.intersection(Equation.horizontal(0)))
        end

        arc = Arc[1, extent: 90]
        F.with_precision(3) { assert(arc.on?([1, -0.0001])) }
        F.with_precision(5) { refute(arc.on?([1, -0.0001])) }
      end

      def test_box_contains_only_the_finite_trace
        arc = Arc[10, starting_angle: 180, extent: 180]
        assert(arc.box.eq?(Rect[20, 10, position: [-10, -10]]))
        assert(arc.reverse.box.eq?(arc.box))
        F.with_precision(0) { assert_equal(arc.box, Arc[10, starting_angle: 180, extent: 180].box) }
      end

      def test_reverse_preserves_trace_and_length
        arc = Arc[4, 2, starting_angle: 350, extent: 120]
        assert_same(arc.ellipse, arc.reverse.ellipse)
        assert(arc.starting.eq?(arc.reverse.ending))
        assert(arc.ending.eq?(arc.reverse.starting))
        assert_equal(arc, arc.reverse.reverse)
        assert_in_delta(arc.length, arc.reverse.length, 1e-9)
        assert_in_delta(5 * Math::PI, Arc[10, extent: -90].length, 1e-12)
      end

      def test_length_matches_elliptic_integral_references
        # Incomplete elliptic integral values evaluated at 60 decimal digits.
        [
          [70, 40, 30, -120],
          110.69526045573414,
          [1, 3, 350, 20],
          1.0424813115985922,
          [1e6, 1, 0, 90],
          1_000_000.0000073509,
          [3, 2, 37, 1e-6],
          4.207259667616972e-8
        ].each_slice(2) do |(rx, ry, starting_angle, extent), expected|
          arc = Arc[rx, ry, starting_angle:, extent:]
          assert_in_delta(expected, arc.length, 1e-9 + (1e-10 * expected))
          assert_in_delta(expected, arc.reverse.length, 1e-9 + (1e-10 * expected))
        end
      end

      def test_approx_validates_rounded_fields_without_mutation
        [-359.999, 359.999].each do |extent|
          arc = Arc[1, extent:]
          assert_raises(Error) { arc.approx(2) }
          assert(arc.eq?(Arc[1, extent: extent.positive? ? 359.998 : -359.998], precision: 2))
        end

        arc = Arc[1, extent: 0.001]
        refute(arc.empty?)
        assert(arc.approx(2).empty?)
        assert_equal(0.001, arc.extent)
      end

      def test_affine_preserves_every_sample_and_direction
        transforms = [
          [:rotate, [37], {}],
          [:scale, [2, 0.5], {}],
          [:scale, [-2, 1], {}],
          [:scale, [-2], {}],
          [:skew_x, [30], {}],
          [:skew_y, [-20], {}],
          [:skew, [10, 20], {}],
          [:reflect, [], {x: true, y: false}],
          [:translate, [3, -2], {}]
        ]
        [Arc[4, 2, rotation: 23, extent: -230], Circle[3].arc(starting_angle: 37, extent: 210)].each do |arc|
          transforms.each do |method, args, kwargs|
            transformed = arc.public_send(method, *args, **kwargs)
            [0, 0.25, 0.5, 0.75, 1].each do |fraction|
              expected = arc
                .ellipse
                .point(arc.starting_angle + (fraction * arc.extent))
                .public_send(method, *args, **kwargs)
              actual = transformed.ellipse.point(transformed.starting_angle + (fraction * transformed.extent))
              assert_in_delta(expected.x, actual.x, 1e-10, method.to_s)
              assert_in_delta(expected.y, actual.y, 1e-10, method.to_s)
            end
          end
        end

        assert(Arc[3, extent: 90].reflect(x: true, y: false).counterclockwise?)
      end

      def test_affine_rejects_singular_transforms
        [Ellipse[4, 2], Circle[3], Arc[4, 2, extent: 90]].each do |element|
          assert_raises(Error) { element.scale(0) }
          assert_raises(Error) { element.scale(1, 0) }
          assert_raises(Error) { element.skew(45, 45) }
        end
      end

      def test_sweep_returns_no_interior_spans
        arc = Arc[5, 3, extent: 180]
        assert_empty(Operation.sweep(arc, initial: Origin, angle: 0, step: 1))
      end
    end
  end
end
