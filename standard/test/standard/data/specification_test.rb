# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Standard
    class SpecificationTest < Minitest::Test
      def test_specified_element_names_are_valid
        Specification.data.each_key { Conform.new(it) }
      end

      def test_expanded_specification_for_linearGradient
        assert_equal(
          {
            attributes: [
              *Attribute[:Core],
              *Attribute[:EventDocumentElement],
              *Attribute[:EventGlobal],
              *Attribute[:Presentation],
              *Attribute[:Style],
              *Attribute[:Xlink],

              :gradientTransform,
              :gradientUnits,
              :href,
              :spreadMethod,
              :x1,
              :x2,
              :y1,
              :y2
            ],

            elements: [
              *Element[:Descriptive],

              :animate,
              :animateTransform,
              :set,
              :stop
            ],

            model: :SomeElements
          },
          Specification[:linearGradient]
        )
      end

      def test_expanded_specification_for_font
        assert_equal(
          {
            attributes: [
              *Attribute[:Core],
              *Attribute[:Presentation],
              *Attribute[:Style],

              :externalResourcesRequired,
              :"horiz-adv-x",
              :"horiz-origin-x",
              :"horiz-origin-y",
              :"vert-adv-y",
              :"vert-origin-x",
              :"vert-origin-y"
            ],

            elements: [
              *Element[:Descriptive],

              :"font-face",
              :glyph,
              :hkern,
              :"missing-glyph",
              :vkern
            ],

            model: :SomeElements
          },
          Specification[:font]
        )
      end

      def test_model_predicate_matches_requested_models
        assert(Standard.model?(:svg, :SomeElements))
        assert(Standard.model?(:text, :NoneElements, :CDataOrSomeElements))
        refute(Standard.model?(:text, :SomeElements))
        refute(Standard.model?(:missing, :SomeElements))
      end

      def test_missing_lookup_doesnt_pollute_cache
        refute(Standard.specification(:missing))
        Specification.send(:charge)

        cache = Specification.instance_variable_get(:@spec)
        refute_includes(cache.keys, :missing)
      ensure
        Specification.send(:flush)
      end

      def test_expand_preserves_raw_specification_data
        Specification.import(
          agentSpec: {
            attributes: %i[Core id],
            elements: %i[Descriptive title],
            model: :SomeElements
          }
        )
        spec = Specification.data[:agentSpec]
        attributes = spec[:attributes].dup
        elements = spec[:elements].dup

        Specification[:agentSpec]

        assert_equal(attributes, spec[:attributes])
        assert_equal(elements, spec[:elements])
      ensure
        Specification.data.delete(:agentSpec)
        Specification.send(:flush)
      end

      def test_expanded_snapshot_is_mutation_isolated
        Specification.import(
          agentSpec: {
            attributes: %i[Core id],
            elements: %i[Descriptive title],
            model: :SomeElements
          }
        )

        spec = Specification[:agentSpec]
        spec[:attributes] << :agentAttribute
        spec[:elements] << :agentElement

        assert_equal(Attribute[:Core], Specification[:agentSpec][:attributes])
        assert_equal(Element[:Descriptive], Specification[:agentSpec][:elements])
      ensure
        Specification.data.delete(:agentSpec)
        Specification.send(:flush)
      end
    end

    class SpecificationConsistencyTest < Minitest::Test
      def setup = Specification.send(:charge)

      def teardown = Specification.send(:flush)

      def test_charge_expands_each_specification
        cache = Specification.instance_variable_get(:@spec)

        assert_equal(Specification.data.keys.sort, cache.keys.sort)
      end

      def test_expanded_names_are_not_duplicated
        Specification.data.each_key do |name|
          spec = Specification.send(:expand, name)

          assert_equal(spec[:attributes].uniq, spec[:attributes], "#{name}: Duplicate attributes")
          assert_equal(spec[:elements].uniq, spec[:elements], "#{name}: Duplicate elements") if spec[:elements]
        end
      end

      def test_expanded_names_belong_to_their_registry
        Specification.data.each_key do |name|
          spec = Specification.send(:expand, name)
          unknown_attributes = spec[:attributes].reject { Attribute.all.include?(it) }
          unknown_elements = (spec[:elements] || []).reject { Element.all.include?(it) }

          assert_empty(unknown_attributes, "#{name}: Unknown attributes")
          assert_empty(unknown_elements, "#{name}: Unknown elements")
        end
      end

      def test_listed_elements_are_not_duplicated_in_any_group
        Specification.data.each do |name, spec|
          next unless (elements = spec[:elements])

          groups = elements.select { |name| Specification.group?(name) }
          themselves = elements - groups

          duplicates = {}

          themselves.each do |element|
            groups.each do |group|
              next unless Element.is?(element, group)

              (duplicates[element] ||= []) << group
            end
          end

          assert_empty(duplicates, "#{name}: Elements already in a group")
        end
      end

      def test_listed_attributes_are_not_duplicated_in_any_group
        Specification.data.each do |name, spec|
          next unless (attributes = spec[:attributes])

          groups = attributes.select { |name| Specification.group?(name) }
          themselves = attributes - groups

          duplicates = {}

          themselves.each do |attribute|
            groups.each do |group|
              next unless Attribute.is?(attribute, group)

              (duplicates[attribute] ||= []) << group
            end
          end

          assert_empty(duplicates, "#{name}: Attributes already in a group")
        end
      end
    end
  end
end
