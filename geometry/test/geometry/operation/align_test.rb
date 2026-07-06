# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Geometry
    module Operation
      class AlignTest < Minitest::Test
        def test_align_moves_element_to_center
          element = Rect[2, 2]
          target = Rect[6, 4, position: [10, 20]]

          assert_equal(Rect[2, 2, position: [12, 21]], Operation.align(element, target, :center))
        end

        def test_alignment_returns_edge_offsets
          element = Rect[2, 2, position: [1, 3]]
          target = Rect[6, 4, position: [10, 20]]

          [
            Point[9, 0],
            Operation.alignment(element, target, :left),
            Point[13, 0],
            Operation.alignment(element, target, :right),
            Point[0, 17],
            Operation.alignment(element, target, :top),
            Point[0, 19],
            Operation.alignment(element, target, :bottom)
          ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
        end

        def test_align_rejects_non_element
          error = assert_raises(OperationInapplicableError) { Operation.align(Object.new, Rect[1, 1]) }

          assert_match(/Not a Geometric Element/, error.message)
        end

        def test_align_rejects_non_element_target
          error = assert_raises(OperationInapplicableError) { Operation.align(Rect[1, 1], Object.new) }

          assert_match(/Not a Geometric Element/, error.message)
        end

        def test_align_rejects_unknown_alignment
          error = assert_raises(Sevgi::ArgumentError) { Operation.align(Rect[1, 1], Rect[2, 2], :middle) }

          assert_equal("No such type of alignment: middle", error.message)
        end
      end
    end
  end
end
