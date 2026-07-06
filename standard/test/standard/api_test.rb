# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Standard
    class ExternalTest < Minitest::Test
      def test_elements_size_is_consistent
        assert_equal(Standard.elements.size, Element.all.size)
      end

      def test_attributes_size_is_consistent
        assert_equal(Standard.attributes.size, Attribute.all.size)
      end

      def test_predicates_reject_non_symbolic_names
        refute(Standard.element?(nil))
        refute(Standard.element?(Object.new))

        refute(Standard.attribute?(nil))
        refute(Standard.attribute?(Object.new))
      end
    end
  end
end
