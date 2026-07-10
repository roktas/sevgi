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

      def test_conform_accepts_scalar_names_without_mutating_inputs
        attributes = ["viewBox"]
        elements = [:g]

        assert(Conform.(:svg, attributes: "viewBox", elements: :g))
        assert(Conform.(:svg, attributes:, elements:))
        assert_equal(["viewBox"], attributes)
        assert_equal([:g], elements)
      end

      def test_conform_rejects_non_list_name_inputs
        assert_raises(ArgumentError) { Conform.(:svg, attributes: false) }
        assert_raises(ArgumentError) { Conform.(:svg, elements: {}) }
      end

      def test_conform_does_not_cache_rejected_usage
        cache = Conform.instance_variable_get(:@cache)
        snapshot = cache.dup
        element = :rect
        cache.delete(element)
        baseline = cache.dup

        assert_raises(InvalidAttributesError) do
          Conform.(element, attributes: :notAnSvgAttribute)
        end

        assert_equal(baseline, cache)
      ensure
        cache&.replace(snapshot) if snapshot
      end

      def test_cdata_only_rejects_child_elements
        error = assert_raises(UnallowedElementsError) do
          Conform.(:title, cdata: "Name", elements: %i[g])
        end

        assert_equal("title: Element(s) not allowed: 'g'", error.message)
      end

      def test_cdata_or_some_rejects_unallowed_elements
        error = assert_raises(UnallowedElementsError) do
          Conform.(:text, cdata: "Name", elements: %i[rect])
        end

        assert_equal("text: Element(s) not allowed: 'rect'", error.message)
      end

      def test_conform_ignores_foreign_namespace_members
        assert(
          Conform.(
            :svg,
            attributes: ["xmlns", "data-role", "_internal", "inkscape:label"],
            elements: ["_internal", "sodipodi:namedview"]
          )
        )
      end

      def test_conform_rejects_object_namespace_bypass
        attribute = Object.new
        element = Object.new
        attribute.define_singleton_method(:to_s) { "inkscape:label" }
        element.define_singleton_method(:to_s) { "sodipodi:namedview" }

        assert_raises(ArgumentError) do
          Conform.(:svg, attributes: [attribute], elements: [])
        end

        assert_raises(ArgumentError) do
          Conform.(:svg, attributes: [], elements: [element])
        end
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

      def test_special_fe_specular_lighting_rejects_extra_shapes
        error = assert_raises(UnallowedElementsError) do
          Conform.(:feSpecularLighting, elements: %i[fePointLight rect])
        end

        assert_equal("feSpecularLighting: Element(s) not allowed: 'rect'", error.message)
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

      def test_special_font_face_rejects_unallowed_elements
        error = assert_raises(UnallowedElementsError) do
          Conform.(:"font-face", elements: %i[desc rect])
        end

        assert_equal("font-face: Element(s) not allowed: 'rect'", error.message)
      end
    end
  end
end
