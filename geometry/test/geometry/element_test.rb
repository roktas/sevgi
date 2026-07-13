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

        %i[Open Close SHORTCUTS].each { refute_includes(Element::Lined.constants(false), it) }
        %i[\[\] call from_points from_segments].each { refute_respond_to(Element::Lined, it) }

        generated = Element.lined(2, open: true)
        %i[\[\] call from_points from_segments].each { assert_respond_to(generated, it) }
        %i[close? open? poly? size].each { refute_respond_to(generated, it) }

        [Line, Rect, Square, Triangle, Parallelogram, Polygon, Polyline].each do |shape|
          %i[build new_by_points new_by_points! new_by_segments].each { refute_respond_to(shape, it) }
          refute_includes(shape.public_instance_methods, :draw!)
        end

        refute_respond_to(Line, :from_segments)
        refute_respond_to(Rect, :from_points)
        refute_respond_to(Rect[1, 2], :draw!)
      end

      def test_lined_factory_builds_constructible_open_and_closed_classes
        shapes = [
          Element.lined.([0, 0], [1, 0], [0, 1]),
          Element.lined(open: true).([0, 0], [1, 0]),
          Element.lined(2).([0, 0], [1, 0]),
          Element.lined(2, open: true).([0, 0], [1, 0], [1, 1]),
          Element.lined(27, open: true).(*Array.new(28) { [it, 0] })
        ]

        assert_equal([4, 2, 3, 3, 28], shapes.map { it.points.size })
        assert_equal([3, 1, 2, 2, 27], shapes.map { it.segments.size })
      end

      def test_lined_factory_rejects_invalid_class_invariants
        [nil, false, 0, -1, 1.5, "2"].each do |size|
          error = assert_raises(Error) { Element.lined(size) }

          assert_match(/segment count/i, error.message)
        end

        [nil, 0, "false", :yes].each do |open|
          error = assert_raises(Error) { Element.lined(1, open:) }

          assert_match(/open flag/i, error.message)
        end
      end

      def test_lined_constructor_notations_match_english
        polygon = Polygon.([0, 0], [2, 0], [1, 1])
        polyline = Polyline.([0, 0], [2, 0], [1, 1])

        [
          Line[5, 30],
          Line.from_length_angle(5, 30),
          Line.([0, 0], [3, 4]),
          Line.from_points([0, 0], [3, 4]),
          Rect[3, 4],
          Rect.from_size(3, 4),
          Rect.([0, 0], [3, 4]),
          Rect.from_corners([0, 0], [3, 4]),
          Square[3],
          Square.from_size(3),
          Square.([0, 0], [3, 3]),
          Square.from_corners([0, 0], [3, 3]),
          Triangle[[2, 0], [2, 90]],
          Triangle.from_segments([2, 0], [2, 90]),
          Triangle.([0, 0], [2, 0], [2, 2]),
          Triangle.from_points([0, 0], [2, 0], [2, 2]),
          Parallelogram[[2, 0], [2, -90]],
          Parallelogram.from_segments([2, 0], [2, -90]),
          Parallelogram.([0, 0], [2, 0], [2, 2], [0, 2]),
          Parallelogram.from_points([0, 0], [2, 0], [2, 2], [0, 2]),
          Polygon[*polygon.segments],
          Polygon.from_segments(*polygon.segments),
          polygon,
          Polygon.from_points(*polygon.points.first(3)),
          Polyline[*polyline.segments],
          Polyline.from_segments(*polyline.segments),
          polyline,
          Polyline.from_points(*polyline.points)
        ].each_slice(2) { |notation, english| assert_equal(notation, english) }
      end

      def test_lined_instance_notations_match_collections
        triangle = Triangle.([0, 0], [2, 0], [1, 1])

        triangle.lines.each_index { assert_same(triangle.lines[it], triangle[it]) }
        triangle.points.each_index { assert_same(triangle.points[it], triangle.call(it)) }
      end

      def test_lined_english_factories_follow_subclasses
        calls = []
        klass = Class.new(Polyline) do
          define_singleton_method(:[]) do |*segments, position: Origin|
            calls << :segments
            super(*segments, position:)
          end

          define_singleton_method(:call) do |*points|
            calls << :points
            super(*points)
          end
        end

        klass.from_segments([1, 0])
        klass.from_points([0, 0], [1, 0])

        assert_equal(%i[segments points], calls)
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
