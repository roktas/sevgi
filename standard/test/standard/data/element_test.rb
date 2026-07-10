# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Standard
    class ElementTest < Minitest::Test
      def test_element_all_has_expected_size
        assert_equal(80, Element.all.size)
      end

      def test_element_group_expands_members
        assert_equal(%i[desc metadata title], Element[:Descriptive])
      end

      def test_element_ignore_accepts_unvalidated_names
        assert(Element.ignore?(:_private))
        assert(Element.ignore?("app:custom"))

        refute(Element.ignore?(:rect))
        refute(Element.ignore?(Object.new))
      end

      def test_element_predicates_check_group_membership
        assert(Element.is?(:hatch, :PaintServer))
        refute(Element.is?(:hatch, :Descriptive))
      end

      def test_element_pick_unpick_partition_groups
        assert_equal(%i[g circle symbol], Element.pick(%i[path g circle symbol font desc], :ShapeBasic, :Structural))
        assert_equal(%i[path font desc], Element.unpick(%i[path g circle symbol font desc], :ShapeBasic, :Structural))
      end
    end
  end
end
