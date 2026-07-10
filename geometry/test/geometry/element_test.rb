# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Geometry
    class ElementTest < Minitest::Test
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
    end
  end
end
