# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Standard
    class ElementTest < Minitest::Test
      def test_total_number_of_elements
        assert_equal(80, Element.all.size)
      end

      def test_expand_element_group
        assert_equal(%i[ desc metadata title ], Element[:Descriptive])
      end

      def test_element_predicates
        assert(Element.is?(:hatch, :PaintServer))
        refute(Element.is?(:hatch, :Descriptive))
      end

      def test_element_pick_unpick
        assert_equal(%i[ g circle symbol ], Element.pick(%i[ path g circle symbol font desc ], :ShapeBasic, :Structural))
        assert_equal(%i[ path font desc ], Element.unpick(%i[ path g circle symbol font desc ], :ShapeBasic, :Structural))
      end
    end
  end
end
