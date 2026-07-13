# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Geometry
    class EquationTest < Minitest::Test
      def test_abstract_equation_cannot_be_constructed
        assert_raises(NoMethodError) { Equation.new }
      end

      def test_rect_intersection_returns_boundary_points
        rect = Rect[2, 7]

        [
          [[2.0, 7.0], [0.0, 1.0]],
          rect.intersection(Line.([0.0, 1.0], [1.0, 4.0]).equation).map(&:deconstruct),
          [[1.0, 0.0], [1.0, 7.0]],
          rect.intersection(Line.([1.0, 1.0], [1.0, 4.0]).equation).map(&:deconstruct),
          [[2.0, 1.0], [0.0, 1.0]],
          rect.intersection(Line.([1.0, 1.0], [5.0, 1.0]).equation).map(&:deconstruct)
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_equation_rect_intersection_returns_single_point
        rect = Rect[2, 4]
        equ = Equation.diagonal(slope: 1.0, intercept: 4.0)

        [
          [[0.0, 4.0]],
          rect.intersection(equ).map(&:deconstruct)
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_equation_hides_incomplete_circle_surface
        assert_respond_to(Equation, :horizontal)
        refute_includes(Geometry.constants(false), :Circle)
        refute_includes(Equation.constants(false), :Quadratic)
      end

      def test_linear_equations_are_unoriented
        [
          Equation.horizontal(1),
          Equation.vertical(1),
          Equation.diagonal(slope: 1, intercept: 0)
        ].each do |equation|
          refute_respond_to(equation, :left?)
          refute_respond_to(equation, :right?)
        end
      end

      def test_linear_equation_categories_are_semantic_siblings
        diagonal = Equation.diagonal(slope: 1, intercept: 0)
        horizontal = Equation.horizontal(1)
        vertical = Equation.vertical(1)

        [diagonal, horizontal, vertical].each { assert_kind_of(Equation::Linear, it) }
        assert_equal([Equation::Linear] * 3, [diagonal, horizontal, vertical].map { it.class.superclass })
        assert_instance_of(Equation::Linear::Diagonal, diagonal)
        assert_instance_of(Equation::Linear::Horizontal, horizontal)
        assert_instance_of(Equation::Linear::Vertical, vertical)
        refute_kind_of(Equation::Linear::Diagonal, horizontal)
        assert_equal(horizontal, Equation.horizontal(1.0))
        assert_equal(horizontal.hash, Equation.horizontal(1.0).hash)
        refute_equal(horizontal, diagonal)
      end

      def test_intersection_precision_controls_result_rounding
        triangle = Triangle[Segment[2, 0], Segment[1, 150]]
        equ = Equation.vertical(1.2)

        [
          [[1.2, 0.0], [1.2, 0.5]],
          triangle.intersection(equ, precision: 1).map(&:deconstruct),
          [[1.2, 0.0], [1.2, 0.4619]],
          triangle.intersection(equ, precision: 4).map(&:deconstruct)
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_intersection_explicit_precision_overrides_thread_precision
        triangle = Triangle[Segment[2, 0], Segment[1, 150]]
        equ = Equation.vertical(1.2)

        F.with_precision(2) do
          assert_equal(
            [[1.2, 0.0], [1.2, 0.5]],
            triangle.intersection(equ, precision: 1).map(&:deconstruct)
          )
        end
      end

      def test_intersection_explicit_precision_controls_membership
        rect = Rect[1, 1]
        equation = Equation.vertical(1.4)

        assert_empty(rect.intersection(equation, precision: 1))

        F.with_precision(0) do
          assert_empty(rect.intersection(equation, precision: 1))
        end
      end

      def test_intersection_precision_controls_duplicate_collapse
        rect = Rect[1, 0.049]
        equation = Equation.vertical(0.5)

        assert_equal([[0.5, 0.0]], rect.intersection(equation, precision: 1).map(&:deconstruct))
        assert_equal([[0.5, 0.0], [0.5, 0.049]], rect.intersection(equation, precision: 3).map(&:deconstruct))
      end

      def test_intersection_nil_uses_thread_precision_for_all_stages
        rect = Rect[1, 1]
        equation = Equation.vertical(1.04)

        F.with_precision(1) do
          assert_equal([[1.0, 0.0], [1.0, 1.0]], rect.intersection(equation).map(&:deconstruct))
        end

        F.with_precision(2) { assert_empty(rect.intersection(equation)) }
      end

      def test_intersect_rejects_non_equation
        error = assert_raises(Error) { Equation.horizontal(1).intersect(Object.new) }

        assert_match(/Must be an equation/, error.message)
      end

      def test_equation_wraps_invalid_numeric_conversion
        numeric = Class.new(Numeric) { def to_f = raise "conversion failed" }.new
        error = assert_raises(Error) { Equation.diagonal(slope: Complex(1, 2), intercept: 0) }
        conversion_error = assert_raises(Error) { Equation.diagonal(slope: numeric, intercept: 0) }

        assert_match(/slope/, error.message)
        assert_match(/slope/, conversion_error.message)
      end

      def test_unimplemented_intersection_raises_panic_error
        assert_raises(PanicError) do
          Equation.horizontal(3).send(:linear_vs_quadratic, Object.new)
        end
      end

      def test_unknown_equation_intersection_raises_panic_error
        custom = Class.new(Equation).allocate
        error = assert_raises(PanicError) { Equation.horizontal(1).intersect(custom) }

        assert_match(/Intersection not implemented/, error.message)
      end
    end
  end
end
