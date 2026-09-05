# frozen_string_literal: true

require_relative "../../test_helper"
require "bigdecimal"

module Sevgi
  module Graphics
    module Mixtures
      class WrappersTest < Minitest::Test
        DOC = :minimal

        Number = Class.new(Numeric) do
          def initialize(value)
            super()
            @value = value
          end

          def to_f = @value.to_f
        end

        def test_arc_wrappers_render_absolute_and_relative_paths
          actual = SVG(DOC) do
            ArcTo(x1: 1, y1: 2, x2: 5, y2: 6, rx: 3, ry: 4, rotation: 30, large: true, id: "absolute")
            ArcBy(dx: 4, dy: -3, rx: 2, ry: 1, x: 5, y: 6, sweep: true, id: "relative")
          end
            .Render()

          assert_includes(actual, "<path id=\"absolute\" d=\"M 1 2 A 3 4 30 1 0 5 6\"/>")
          assert_includes(actual, "<path id=\"relative\" d=\"M 5 6 a 2 1 0 0 1 4 -3\"/>")
        end

        def test_arc_wrappers_preserve_svg_radius_handling
          actual = SVG(DOC) do
            ArcTo(x2: 100, y2: 0, rx: 1, ry: 1)
            ArcBy(dx: 10, dy: 5, rx: 0, ry: -2)
            ArcTo(x2: 0, y2: 0, rx: 1, ry: 1)
          end
            .Render()

          ["M 0 0 A 1 1 0 0 0 100 0", "M 0 0 a 0 -2 0 0 0 10 5", "M 0 0 A 1 1 0 0 0 0 0"].each do |data|
            assert_includes(actual, "d=\"#{data}\"")
          end
        end

        def test_arc_wrappers_reject_invalid_operands_before_drawing
          [
            [:ArcTo, {x1: 0, y1: 0, x2: 1, y2: 2, rx: 3, ry: 4, rotation: 0}],
            [:ArcBy, {x: 0, y: 0, dx: 1, dy: 2, rx: 3, ry: 4, rotation: 0}]
          ].each do |method, arguments|
            arguments.keys.product(["1", Complex(1, 0), Float::INFINITY, Float::NAN]).each do |field, value|
              document = SVG(DOC)
              assert_raises(Sevgi::ArgumentError) { document.public_send(method, **arguments, field => value) }
              assert_empty(document.children)
            end

            %i[large sweep].product([nil, 0, 1, "false"]).each do |field, value|
              document = SVG(DOC)
              assert_raises(Sevgi::ArgumentError) { document.public_send(method, **arguments, field => value) }
              assert_empty(document.children)
            end
          end
        end

        def test_arc_wrappers_normalize_svg_numbers
          actual = SVG(DOC) do
            ArcTo(x2: Rational(1, 2), y2: BigDecimal("1.5"), rx: Number.new(2), ry: BigDecimal("3"))
            ArcBy(dx: Rational(1, 2), dy: BigDecimal("1.5"), rx: Number.new(2), ry: BigDecimal("3"))
          end
            .Render()

          assert_includes(actual, "d=\"M 0 0 A 2 3 0 0 0 0.5 1.5\"")
          assert_includes(actual, "d=\"M 0 0 a 2 3 0 0 0 0.5 1.5\"")
        end

        def test_line_wrappers_build_path_commands
          expected = <<~SVG
            <svg>
              <path id="line-to" d="M 0 0 L 1 2"/>
              <path id="hline-to" d="M 0 0 H 3"/>
              <path id="vline-to" d="M 0 0 V 4"/>
              <path id="line-by" d="M 0 0 l 5 0"/>
              <path id="relh" d="M 0 0 h 5"/>
              <path id="relv" d="M 0 0 v 6"/>
            </svg>
          SVG
            .chomp

          actual = SVG(DOC) do
            LineTo(id: "line-to", x2: 1, y2: 2)
            HLineTo(id: "hline-to", x2: 3)
            VLineTo(id: "vline-to", y2: 4)
            LineBy(id: "line-by", angle: 0, length: 5)
            HLineBy(id: "relh", length: 5)
            VLineBy(id: "relv", length: 6)
          end
            .Render()

          assert_equal(expected, actual)
        end

        def test_line_by_rejects_non_finite_real_operands
          invalid = ["oops", Complex(1, 2), Float::INFINITY, Float::NAN]

          %i[angle length x y].product(invalid).each do |field, value|
            document = SVG(DOC)
            arguments = {:angle => 0, :length => 1, :x => 0, :y => 0, field => value}

            assert_raises(Sevgi::ArgumentError) { document.LineBy(**arguments) }
            assert_empty(document.children)
          end
        end

        def test_line_by_renders_normalized_svg_numbers
          actual = SVG(DOC) do
            LineBy(
              angle: Rational(0, 1),
              length: BigDecimal("2"),
              x: Rational(1, 2),
              y: BigDecimal("1.5")
            )
          end
            .Render()

          assert_match(/d="M 0.5 1.5 l 2 0"/, actual)
          refute_match(%r{(?:1/2|0\.\d+e\d+)}, actual)
        end

        def test_numeric_wrappers_normalize_every_owned_slot
          [
            2,
            -2.5,
            Rational(1, 2),
            BigDecimal("1.25"),
            Number.new(Rational(-3, 2))
          ].each do |value|
            number = Float(value)
            number = number.to_i if number == number.to_i

            actual = SVG(DOC) do
              LineTo(x1: value, y1: value, x2: value, y2: value)
              HLineTo(x1: value, y1: value, x2: value)
              VLineTo(x1: value, y1: value, y2: value)
              HLineBy(x: value, y: value, length: value)
              VLineBy(x: value, y: value, length: value)
              LineBy(x: value, y: value, angle: value, length: value)
              square(length: value)
            end
              .Render()

            [
              "d=\"M #{number} #{number} L #{number} #{number}\"",
              "d=\"M #{number} #{number} H #{number}\"",
              "d=\"M #{number} #{number} V #{number}\"",
              "d=\"M #{number} #{number} h #{number}\"",
              "d=\"M #{number} #{number} v #{number}\"",
              "width=\"#{number}\" height=\"#{number}\""
            ].each { assert_includes(actual, it) }

            actual.scan(/d="([^"]+)"/).flatten.each do |data|
              data.split.reject { %w[M L H V l h v].include?(it) }.each { Float(it) }
            end
          end
        end

        def test_numeric_wrappers_reject_non_finite_slots
          [
            [:LineTo, {x1: 0, y1: 0, x2: 1, y2: 1}],
            [:HLineTo, {x1: 0, y1: 0, x2: 1}],
            [:VLineTo, {x1: 0, y1: 0, y2: 1}],
            [:HLineBy, {x: 0, y: 0, length: 1}],
            [:VLineBy, {x: 0, y: 0, length: 1}],
            [:square, {length: 1}]
          ].each do |method, arguments|
            arguments.each_key do |field|
              document = SVG(DOC)

              assert_raises(Sevgi::ArgumentError) do
                document.public_send(method, **arguments, field => Float::INFINITY)
              end

              assert_empty(document.children)
            end
          end
        end

        def test_shape_and_symbol_wrappers_build_elements
          expected = <<~SVG
            <svg>
              <rect id="box" width="7" height="7"/>
              <symbol id="alert-icon">
                <title>Alert Icon</title>
                <rect width="1"/>
              </symbol>
            </svg>
          SVG
            .chomp

          actual = SVG(DOC) do
            square(id: "box", length: 7)
            Symbol("Alert Icon") { rect(width: 1) }
          end
            .Render()

          assert_equal(expected, actual)
        end

        def test_css_wrapper_renders_cdata_style
          expected = <<~SVG
            <svg>
              <style type="text/css">
                <![CDATA[
                  rect {
                    fill: red;
                  }
                ]]>
              </style>
            </svg>
          SVG
            .chomp

          actual = SVG(DOC) do
            css(rect: {fill: "red"})
          end
            .Render()

          assert_equal(expected, actual)
        end

        def test_css_wrapper_accepts_style_attributes
          actual = SVG(DOC) do
            css({rect: {fill: "red"}}, id: "main-style")
          end
            .Render()

          assert_match(%r{<style id="main-style" type="text/css">}, actual)
        end

        def test_css_wrapper_rejects_malformed_styles
          doc = SVG(DOC)
          error = assert_raises(ArgumentError) { doc.css(rect: Object.new) }

          assert_match(/\bMalformed style\b/, error.message)
          assert_empty(doc.children)
        end
      end
    end
  end
end
