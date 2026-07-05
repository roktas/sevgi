# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Standard
    class ConformTest < Minitest::Test
      def test_svg_allows_viewbox_and_group
        assert(Conform.(:svg, attributes: %i[viewBox], elements: %i[g]))
      end

      def test_svg_rejects_lowercase_viewbox
        assert_raises(InvalidAttributesError) do
          Conform.(:svg, attributes: %i[viewbox], elements: %i[g])
        end
      end

      def test_special_fe_diffuse_lighting
        assert(Conform.(:feDiffuseLighting, attributes: %i[surfaceScale], elements: %i[desc fePointLight]))

        assert_raises(UnallowedElementsError) do
          Conform.(:feDiffuseLighting, attributes: %i[surfaceScale], elements: %i[desc g fePointLight])
        end
      end

      def test_conform_defaults_elements_to_empty_list
        assert(Conform.(:rect, attributes: []))
      end

      def test_conform_ignores_foreign_namespace_members
        assert(
          Conform.(
            :svg,
            attributes: %i[xmlns data-role _internal inkscape:label],
            elements: %i[_internal sodipodi:namedview]
          )
        )
      end

      def test_conform_validates_reserved_namespace_members
        assert(Conform.(:text, attributes: [:"xml:space"], cdata: "hello", elements: []))

        error = assert_raises(InvalidAttributesError) do
          Conform.(:svg, attributes: [:"xlink:missing"], elements: [])
        end

        assert_equal("svg: Invalid attribute(s): 'xlink:missing'", error.message)
      end

      def test_special_fe_specular_lighting_checks_order
        assert(Conform.(:feSpecularLighting, elements: %i[fePointLight desc]))

        error = assert_raises(UnmetConditionError) do
          Conform.(:feSpecularLighting, elements: %i[desc fePointLight])
        end

        assert_equal(
          "feSpecularLighting: Condition unmet for the element: 'Exactly one FilterLightSource element as first required'",
          error.message
        )
      end

      def test_special_font_face_rejects_duplicate_font_face
        assert(Conform.(:"font-face", elements: %i[desc font-face title]))

        error = assert_raises(UnmetConditionError) do
          Conform.(:"font-face", elements: %i[font-face font-face])
        end

        assert_equal(
          "font-face: Condition unmet for the element: 'At most one font-face element allowed'",
          error.message
        )
      end
    end
  end
end
