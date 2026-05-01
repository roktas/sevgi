# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Standard
    class AttributeTest < Minitest::Test
      def test_total_number_of_attributes
        assert_equal(385, Attribute.all.size)
      end

      def test_expand_attribute_group
        assert_equal(%i[ onactivate onfocusin onfocusout ], Attribute[:EventGraphical])
      end

      def test_attribute_predicates
        assert(Attribute.is?(:id, :Core))
        refute(Attribute.is?(:style, :Core))
      end

      def test_attribute_pick_unpick
        assert_equal(%i[ class stroke-width style color ], Attribute.pick(%i[ class stroke-width width accelerate style color ], :Presentation, :Style))
        assert_equal(%i[ width accelerate ], Attribute.unpick(%i[ class stroke-width width accelerate style color ], :Presentation, :Style))
      end
    end
  end
end
