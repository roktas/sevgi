# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class ImprintTest < Minitest::Test
        def test_imprint_builds_a_declaration_without_changing_svg
          drawing = SVG width: 20, height: 20 do
            g id: "ink" do
              rect width: 10, height: 10, fill: "none", stroke: "black"
            end
          end
          svg = drawing.call
          result = drawing.Imprint do
            Target "ink", selectors: ["#ink"]
            Param "display", targets: ["ink"], property: "display",
              schema: {type: "string", enum: %w[inline none]}
            Param "opacity", targets: ["ink"], property: "stroke-opacity",
              schema: {type: "number", minimum: 0, maximum: 1}, value: 0.8
            Group "Ink", parameters: ["opacity"]
            Profiles "print", name: "Printer", parameters: ["opacity"], profiles: [
              {id: "original", name: "Original", overrides: {}},
              {id: "light", name: "Light", overrides: {opacity: 0.4}}
            ]
          end
          assert_same(drawing, result)
          assert_equal(svg, drawing.call)
          declaration = drawing.Imprint
          assert_equal(["#ink"], declaration.fetch("targets").fetch("ink").fetch("selectors"))
          assert_equal("stroke-opacity", declaration.fetch("parameters").fetch("opacity").fetch("binding").fetch("property"))
          assert_equal(0.8, declaration.fetch("parameters").fetch("opacity").fetch("value"))
          assert_equal(%w[original light], declaration.fetch("profileSets").first.fetch("profiles").map { it.fetch("id") })
          assert_equal(["opacity"], declaration.fetch("groups").first.fetch("parameters"))
        end

        def test_page_metadata_works_without_paint_and_owns_its_values
          name = +"ITAL-ARCH-60A4-WXGF"
          tags = ["practice"]
          drawing = SVG()
          original = drawing.call
          drawing.Imprint do
            Page name:, tags:
          end
          name.replace("changed")
          tags << "later"
          assert_equal({"targets" => {}, "parameters" => {}, "page" => {"name" => "ITAL-ARCH-60A4-WXGF", "tags" => ["practice"]}}, drawing.Imprint)
          assert_equal(original, drawing.call)
          assert_raises(FrozenError) { drawing.dup.Imprint.fetch("page").fetch("tags") << "other" }
          assert_raises(Sevgi::ArgumentError) do
            SVG().Imprint do
              Page name: "First"
              Page tags: ["second"]
            end
          end
        end

        def test_imprint_owns_input_and_document_copies
          source = {targets: {ink: {selectors: [+"#ink"]}}, parameters: {}}
          drawing = SVG()
          drawing.Imprint source
          copy = drawing.dup
          selector = source[:targets][:ink][:selectors].first
          refute_predicate(selector, :frozen?)
          selector.replace("#changed")
          source[:targets][:ink][:selectors] << "#later"
          assert_equal(["#ink"], copy.Imprint.fetch("targets").fetch("ink").fetch("selectors"))
          assert_raises(FrozenError) { copy.Imprint.fetch("targets").clear }
          copy.Imprint targets: {}, parameters: {}
          assert_equal(["ink"], drawing.Imprint.fetch("targets").keys)
          assert_empty(copy.Imprint.fetch("targets"))
        end

        def test_imprint_stays_local_to_parallel_documents
          drawings = %w[first second].map do |id|
            Thread.new do
              SVG().tap { it.Imprint targets: {id => {selectors: ["##{id}"]}}, parameters: {} }
            end
          end.map(&:value)
          assert_equal([["first"], ["second"]], drawings.map { it.Imprint.fetch("targets").keys })
          assert_nil(SVG().Imprint)
        end

        def test_imprint_rejects_ambiguous_or_non_json_data
          cycle = []
          cycle << cycle
          deep = 0
          33.times { deep = [deep] }
          definitions = [
            {targets: {}, "targets" => {}, parameters: {}},
            {targets: {}, parameters: {opacity: {value: Float::NAN}}},
            {targets: {}, parameters: {}, groups: cycle},
            {targets: {}, parameters: {}, groups: [Object.new]},
            {targets: {}, parameters: {}, unknown: true},
            {targets: {}, parameters: {}, groups: ["\xff".b]},
            {targets: {}, parameters: {}, groups: deep}
          ]
          definitions.each { |definition| assert_raises(Sevgi::ArgumentError) { SVG().Imprint definition } }
          assert_raises(Sevgi::ArgumentError) do
            SVG().Imprint do
              Target "ink", selectors: ["#ink"]
              Target :ink, selectors: ["#other"]
            end
          end
        end

        def test_imprint_keeps_svg_style_elements_available
          drawing = SVG do
            style "rect { fill: red; }"
          end
          assert_includes(drawing.call, "<style>")
          assert_nil(drawing.Imprint)
          assert_raises(Sevgi::ArgumentError) { drawing.rect.Imprint targets: {}, parameters: {} }
        end
      end
    end
  end
end
