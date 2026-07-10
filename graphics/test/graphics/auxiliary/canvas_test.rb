# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    class CanvasTest < Minitest::Test
      def test_canvas_attributes_include_viewport_and_viewbox
        canvas = Canvas.from_paper(:a4, margins: [3, 5])

        [
          {width: "210.0mm", height: "297.0mm"},
          canvas.viewport,
          "-5 -3 210 297",
          canvas.viewbox,
          "0 0 210 297",
          canvas.viewbox(0),
          "1 2 210 297",
          canvas.viewbox([1, 2])
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_canvas_inner_size_excludes_margins
        canvas = Canvas.from_paper(:a4, margins: [3, 5])

        [
          210.0 - (2 * 5.0),
          canvas.inner.width,
          297.0 - (2 * 3.0),
          canvas.inner.height
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_canvas_accepts_paper_profile_object
        canvas = Canvas.from_paper(Paper.a4, margins: [3, 5])

        [
          Paper.a4,
          canvas.size,
          [3.0, 5.0, 3.0, 5.0],
          canvas.margin.to_a
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_canvas_rejects_unknown_paper_profile
        error = assert_raises(ArgumentError) { Canvas.from_paper(:missing_paper) }

        assert_match(/\bmissing_paper\b/, error.message)
      end

      def test_canvas_with_preserves_size_and_updates_margins
        canvas = Canvas.from_paper(:a4)
        updated = canvas.with(margins: [1, 2, 3, 4])

        [
          canvas.size,
          updated.size,
          [1.0, 2.0, 3.0, 4.0],
          updated.margin.to_a
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_canvas_with_replaces_size_fields
        canvas = Canvas.from_paper(:a4)

        [
          100.0,
          canvas.with(width: 100).width,
          200.0,
          canvas.with(height: 200).height,
          :px,
          canvas.with(unit: :px).unit,
          :custom_icon,
          canvas.with(name: :custom_icon).name
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_canvas_with_replaces_combined_fields
        canvas = Canvas.from_paper(:a4, margins: [1])
        updated = canvas.with(width: 16, height: 32, unit: :px, name: :icon, margins: [2, 3])

        [
          16.0,
          updated.width,
          32.0,
          updated.height,
          :px,
          updated.unit,
          :icon,
          updated.name,
          [2.0, 3.0, 2.0, 3.0],
          updated.margin.to_a
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_canvas_with_rejects_unknown_options
        canvas = Canvas.from_paper(:a4)

        error = assert_raises(ArgumentError) { canvas.with(color: "red") }

        assert_match(/\bcolor\b/, error.message)
      end

      def test_canvas_rejects_invalid_origin
        canvas = Canvas.from_paper(:a4)

        assert_raises(ArgumentError) { canvas.viewbox([1]) }
        assert_raises(ArgumentError) { canvas.viewbox(:origin) }

        x_error = assert_raises(ArgumentError) { canvas.viewbox(["x", 2]) }
        y_error = assert_raises(ArgumentError) { canvas.viewbox([1, Object.new]) }

        assert_match(/\bx\b/, x_error.message)
        assert_match(/\by\b/, y_error.message)
      end

      def test_canvas_origin_requires_finite_real_coordinates
        canvas = Canvas.from_paper(:a4)

        [
          -> { canvas.viewbox("1") },
          -> { canvas.viewbox([Complex(1, 0), 2]) },
          -> { canvas.viewbox([Float::NAN, 2]) },
          -> { canvas.viewbox([Float::INFINITY, 2]) }
        ].each { |operation| assert_raises(Sevgi::ArgumentError, &operation) }
      end

      def test_canvas_rejects_invalid_margins_and_overflow
        [
          -> { Canvas.from_paper(:a4, margins: [-1]) },
          -> { Canvas.from_paper(:a4, margins: [Float::NAN]) },
          -> { Canvas.from_paper(:a4, margins: [Float::INFINITY]) },
          -> { Canvas.from_paper(:a4, margins: [106]) }
        ].each { |operation| assert_raises(Sevgi::ArgumentError, &operation) }
      end

      def test_canvas_with_preserves_source_after_valid_replacement
        source = Canvas.from_paper(:a4, margins: [3, 5])
        updated = source.with(width: 100, height: 200, margins: [1])

        assert_equal([210.0, 297.0, [3.0, 5.0, 3.0, 5.0]], [source.width, source.height, source.margin.to_a])
        assert_equal([100.0, 200.0, [1.0, 1.0, 1.0, 1.0]], [updated.width, updated.height, updated.margin.to_a])
      end
    end

  end
end
