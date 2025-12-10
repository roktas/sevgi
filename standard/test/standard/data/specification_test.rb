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

            elements:   [
              *Element[:Descriptive],

              :animate,
              :animateTransform,
              :set,
              :stop
            ],

            model:      :SomeElements
          },
          Specification[:linearGradient],
        )
      end

      def test_expanded_specification_for_font
        assert_equal(
          {
            attributes: [
              *Attribute[:Core],
              *Attribute[:Presentation],
              *Attribute[:Style],

              :"externalResourcesRequired",
              :"horiz-adv-x",
              :"horiz-origin-x",
              :"horiz-origin-y",
              :"vert-adv-y",
              :"vert-origin-x",
              :"vert-origin-y"
            ],

            elements:   [
              *Element[:Descriptive],

              :"font-face",
              :"glyph",
              :"hkern",
              :"missing-glyph",
              :"vkern"
            ],

            model:      :SomeElements
          },
          Specification[:font],
        )
      end
    end

    class SpecificationConsistencyTest < Minitest::Test
      def setup    = Specification.send(:charge)

      def teardown = Specification.send(:flush)

      def test_listed_elements_are_not_duplicated_in_any_group
        Specification.data.each do |name, spec|
          next unless (elements = spec[:elements])

          groups     = elements.select { |name| Specification.group?(name) }
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

          groups     = attributes.select { |name| Specification.group?(name) }
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
