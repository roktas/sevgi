# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Standard
    class AttributeTest < Minitest::Test
      def test_attribute_all_has_expected_size
        assert_equal(385, Attribute.all.size)
      end

      def test_attribute_group_expands_members
        assert_equal(%i[onactivate onfocusin onfocusout], Attribute[:EventGraphical])
      end

      def test_attribute_predicates_check_group_membership
        assert(Attribute.is?(:id, :Core))
        refute(Attribute.is?(:style, :Core))
      end

      def test_attribute_pick_unpick_partition_groups
        assert_equal(
          %i[class stroke-width style color],
          Attribute.pick(%i[class stroke-width width accelerate style color], :Presentation, :Style)
        )
        assert_equal(
          %i[width accelerate],
          Attribute.unpick(%i[class stroke-width width accelerate style color], :Presentation, :Style)
        )
      end
    end
  end
end
