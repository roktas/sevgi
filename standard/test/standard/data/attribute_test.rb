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

      def test_attribute_set_accepts_string_and_symbol_groups
        expected = Attribute.set(:EventGraphical)

        assert_equal(expected, Attribute.set("EventGraphical"))
        assert_equal(expected, Attribute.set(:EventGraphical, "EventGraphical"))
      end

      def test_attribute_set_rejects_unknown_groups_without_mutation
        before = Attribute.all
        error = assert_raises(ArgumentError) { Attribute.set(:UnknownGroup) }

        assert_match(/Unknown SVG group/, error.message)
        assert_equal(before, Attribute.all)
      end

      def test_attribute_ignore_accepts_unvalidated_names
        assert(Attribute.ignore?(:_private))
        assert(Attribute.ignore?("data-value"))
        assert(Attribute.ignore?("app:custom"))
        assert(Attribute.ignore?("xmlns"))

        refute(Attribute.ignore?(:xlink))
        refute(Attribute.ignore?("xlink:href"))
        refute(Attribute.ignore?(Object.new))
      end

      def test_attribute_predicates_check_group_membership
        assert(Attribute.is?(:id, :Core))
        refute(Attribute.is?(:style, :Core))
      end

      def test_attribute_deprecated_group_excludes_valid_filter_attributes
        refute(Attribute.is?(:amplitude, :Deprecated))
        assert(Attribute.is?(:amplitude, :FilterTransferFunction))
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
