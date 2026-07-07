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

      def test_canvas_rejects_invalid_origin
        canvas = Canvas.from_paper(:a4)

        assert_raises(ArgumentError) { canvas.viewbox([1]) }
        assert_raises(ArgumentError) { canvas.viewbox(:origin) }
      end
    end

    class MarginTest < Minitest::Test
      def test_margin_expands_css_like_values
        [
          [0.0, 0.0, 0.0, 0.0],
          Margin.margin(nil).to_a,
          [1.0, 1.0, 1.0, 1.0],
          Margin.margin([1]).to_a,
          [1.0, 2.0, 1.0, 2.0],
          Margin.margin([1, 2]).to_a,
          [1.0, 2.0, 3.0, 2.0],
          Margin.margin([1, 2, 3]).to_a,
          [1.0, 2.0, 3.0, 4.0],
          Margin.margin([1, 2, 3, 4]).to_a
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end

      def test_margin_axis_totals_and_adjust
        margin = Margin[1, 2, 3, 4]

        [
          6.0,
          margin.horizontal,
          4.0,
          margin.vertical,
          [6.0, 5.0, 8.0, 7.0],
          margin.adjust(3, 5).to_a
        ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      end
    end
  end
end
