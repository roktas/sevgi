# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class StyleTest < Minitest::Test
        def test_style_builds_a_declaration_without_changing_svg
          drawing = SVG width: 20, height: 20 do
            g id: "ink" do
              rect width: 10, height: 10, fill: "none", stroke: "black"
            end
          end
          svg = drawing.call
          result = drawing.Style do
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
          style = drawing.Style
          assert_equal(["#ink"], style.fetch("targets").fetch("ink").fetch("selectors"))
          assert_equal("stroke-opacity", style.fetch("parameters").fetch("opacity").fetch("binding").fetch("property"))
          assert_equal(0.8, style.fetch("parameters").fetch("opacity").fetch("value"))
          assert_equal(%w[original light], style.fetch("profileSets").first.fetch("profiles").map { it.fetch("id") })
          assert_equal(["opacity"], style.fetch("groups").first.fetch("parameters"))
        end

        def test_style_owns_input_and_document_copies
          source = {targets: {ink: {selectors: [+"#ink"]}}, parameters: {}}
          drawing = SVG()
          drawing.Style source
          copy = drawing.dup
          selector = source[:targets][:ink][:selectors].first
          refute_predicate(selector, :frozen?)
          selector.replace("#changed")
          source[:targets][:ink][:selectors] << "#later"
          assert_equal(["#ink"], copy.Style.fetch("targets").fetch("ink").fetch("selectors"))
          assert_raises(FrozenError) { copy.Style.fetch("targets").clear }
          copy.Style targets: {}, parameters: {}
          assert_equal(["ink"], drawing.Style.fetch("targets").keys)
          assert_empty(copy.Style.fetch("targets"))
        end

        def test_style_stays_local_to_parallel_documents
          drawings = %w[first second].map do |id|
            Thread.new do
              SVG().tap { it.Style targets: {id => {selectors: ["##{id}"]}}, parameters: {} }
            end
          end.map(&:value)
          assert_equal([["first"], ["second"]], drawings.map { it.Style.fetch("targets").keys })
          assert_nil(SVG().Style)
        end

        def test_style_rejects_ambiguous_or_non_json_data
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
          definitions.each { |definition| assert_raises(Sevgi::ArgumentError) { SVG().Style definition } }
          assert_raises(Sevgi::ArgumentError) do
            SVG().Style do
              Target "ink", selectors: ["#ink"]
              Target :ink, selectors: ["#other"]
            end
          end
        end

        def test_style_keeps_svg_style_elements_available
          drawing = SVG do
            style "rect { fill: red; }"
          end
          assert_includes(drawing.call, "<style>")
          assert_nil(drawing.Style)
          assert_raises(Sevgi::ArgumentError) { drawing.rect.Style targets: {}, parameters: {} }
        end
      end
    end
  end
end
