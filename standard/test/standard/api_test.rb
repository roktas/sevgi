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

      def test_public_names_accept_string_and_symbol
        assert(Standard.element?(:svg))
        assert(Standard.element?("svg"))
        assert(Standard.attribute?(:viewBox))
        assert(Standard.attribute?("viewBox"))
        assert_equal(Standard.specification(:svg), Standard.specification("svg"))
        assert(Standard.model?("text", "CDataOrSomeElements"))
        assert(Standard.conform("svg", attributes: ["viewBox"], elements: ["g"]))
      end

      def test_public_names_reject_non_string_symbol_objects
        object = Object.new

        assert_raises(ArgumentError) { Standard.element?(nil) }
        assert_raises(ArgumentError) { Standard.element?(object) }
        assert_raises(ArgumentError) { Standard.attribute?(nil) }
        assert_raises(ArgumentError) { Standard.attribute?(object) }
        assert_raises(ArgumentError) { Standard.specification(object) }
        assert_raises(ArgumentError) { Standard.model?(object, :SomeElements) }
        assert_raises(ArgumentError) { Standard.conform(object) }
      end

      def test_specification_returns_element_contract
        assert_equal(Standard.specification(:svg), Standard[:svg])
        assert_includes(Standard.specification(:svg).keys, :attributes)
      end

      def test_supported_element_names_match_specifications
        element = Standard.const_get(:Element)
        specification = Standard.const_get(:Specification)

        assert_equal(element.all, Set[*specification.send(:data).keys])
      end

      def test_supported_element_policy
        assert(Standard.element?(:discard))
        refute(Standard.element?(:solidcolor))
      end

      def test_public_sets_are_mutation_isolated
        Standard.attributes.clear
        Standard.elements.clear

        assert(Standard.attribute?(:id))
        assert(Standard.element?(:svg))
      end

      def test_public_group_names_exactly_match_filter_vocabularies
        attribute = Standard.const_get(:Attribute)
        element = Standard.const_get(:Element)

        assert_equal(Set[*attribute.send(:data).keys], Standard.attribute_groups)
        assert_equal(Set[*element.send(:data).keys], Standard.element_groups)

        Standard.attribute_groups.each { refute_empty(Standard.attributes(it)) }
        Standard.element_groups.each { refute_empty(Standard.elements(it.to_s)) }
      end

      def test_public_group_names_are_immutable
        assert_predicate(Standard.attribute_groups, :frozen?)
        assert_predicate(Standard.element_groups, :frozen?)
        assert_raises(FrozenError) { Standard.attribute_groups.clear }
        assert_raises(FrozenError) { Standard.element_groups << :AgentGroup }

        assert_includes(Standard.attribute_groups, :Core)
        assert_includes(Standard.element_groups, :Descriptive)
      end

      def test_specification_hash_is_mutation_isolated
        Standard.specification(:svg).clear

        assert_includes(Standard.specification(:svg).keys, :attributes)
      end

      def test_specification_nested_arrays_are_mutation_isolated
        Standard.specification(:svg)[:attributes].clear
        Standard.specification(:svg)[:elements] << :agentElement

        assert_includes(Standard.specification(:svg)[:attributes], :id)
        refute_includes(Standard.specification(:svg)[:elements], :agentElement)
      end

      def test_specification_rejects_invalid_names
        assert_nil(Standard.specification(:missing))
        assert_raises(ArgumentError) { Standard[nil] }
        assert_raises(ArgumentError) { Standard.specification("not a qname") }
      end
    end
  end
end
