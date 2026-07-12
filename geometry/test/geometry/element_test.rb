# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Geometry
    class ElementTest < Minitest::Test
      def test_abstract_element_cannot_be_constructed
        assert_raises(NoMethodError) { Element.new }
      end

      def test_lined_element_copies_constructor_inputs
        point = [0, 0]
        segment = [2, 0]
        polygon = Polygon.from_points(point, [2, 0], [1, 1])
        polyline = Polyline.from_segments(segment)

        point[0] = 9
        segment[0] = 9

        assert_equal(Point[0, 0], polygon.points.first)
        assert_equal(Segment[2, 0], polyline.segments.first)
      end

      def test_lined_element_exposes_immutable_collections
        rect = Rect[2, 3]

        rect.lines
        rect.equations
        rect.box

        [
          rect.points,
          rect.points(true),
          rect.segments,
          rect.segments(true),
          rect.lines,
          rect.equations
        ].each do |collection|
          assert_predicate(collection, :frozen?)
          assert_raises(FrozenError) { collection << Object.new }
        end
      end

      def test_lined_element_hides_incomplete_builders
        assert_respond_to(Element, :lined)
        refute_respond_to(Element, :arced)
        refute_includes(Element.constants(false), :Arced)
      end

      def test_lined_element_equality_is_exact
        left = Rect[1.04, 1.04]
        right = Rect[1.0, 1.0]

        F.with_precision(1) do
          refute_equal(left, right)
          refute_equal(left.hash, right.hash)
          assert(left.eq?(right, precision: 1))
          refute(left.eq?(right, precision: 2))
        end
      end

      def test_lined_element_hash_is_stable_across_precision
        element = Rect[1.04, 1.04]
        hash = nil
        thread_hash = nil

        F.with_precision(1) { hash = {element => :ok} }
        Thread.new { F.with_precision(1) { thread_hash = {element => :ok} } }.join

        assert_equal(:ok, hash[element])
        assert_equal(:ok, thread_hash[element])
      end

      def test_lined_affinity_and_at_reject_invalid_operands
        element = Rect[2, 3]
        original = element.points

        [
          -> { element.at(dx: "oops") },
          -> { element.at(dy: Float::INFINITY) },
          -> { element.rotate("oops") },
          -> { element.scale(Complex(1, 0)) },
          -> { element.skew(Float::NAN) },
          -> { element.translate(Object.new) },
          -> { element.reflect(x: 1) }
        ].each { |operation| assert_raises(Error, &operation) }

        assert_same(original, element.points)
      end

      def test_lined_affinity_preserves_or_widens_shape_class
        [
          Line[2, 30],
          Line,
          Triangle[[2, 0], [2, 90]],
          Triangle,
          Parallelogram[[2, 0], [2, 90]],
          Parallelogram,
          Polygon.([0, 0], [2, 0], [1, 1]),
          Polygon,
          Polyline.([0, 0], [2, 0], [1, 1]),
          Polyline
        ].each_slice(2) { |shape, klass| assert_instance_of(klass, shape.rotate(30)) }

        rect = Rect[2, 3]
        square = Square[2]

        assert_instance_of(Rect, rect.translate(1, 2))
        assert_instance_of(Rect, rect.rotate(90))
        assert_instance_of(Parallelogram, rect.rotate(30))
        assert_instance_of(Parallelogram, rect.skew_x(15))
        assert_instance_of(Square, square.translate(1, 2))
        assert_instance_of(Rect, square.scale(2, 1))
        assert_instance_of(Parallelogram, square.rotate(30))
      end

      def test_widened_rect_draws_transformed_points
        attrs = nil
        node = Object.new
        node.define_singleton_method(:polygon) { |**kwargs| attrs = kwargs }
        result = Rect[2, 3, position: [1, 1]].rotate(30)

        result.draw(node)

        assert_equal(result.points(true).map { it.deconstruct.join(",") }, attrs[:points])
      end
    end
  end
end
