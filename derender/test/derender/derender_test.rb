# frozen_string_literal: true

require "tmpdir"

require_relative "../test_helper"

module Sevgi
  module Derender
    class DerenderTest < Minitest::Test
      COLLISION_ELEMENTS = {
        "exit" => "0",
        "object_id" => "object-id",
        "raise" => "derender-raise",
        "send" => "object_id",
        "system" => nil
      }.freeze

      def test_derender_converts_selected_node_to_dsl
        expected = <<~SEVGI
          g id: "xxx" do
            line id: "line1", length: 10.0
            line id: "line2", length: 20.0
            text do
              _ "You are"
              tspan "not", "font-weight": "bold"
              _ "a banana"
            end
          end
        SEVGI

        svg = <<~SVG
          <g id="xxx">
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
            <text>
              You are
              <tspan font-weight="bold">not</tspan>
              a banana
            </text>
          </g>
        SVG
          .chomp

        actual = Derender.derender(svg, id: "xxx")

        assert_equal(expected, actual)
      end

      def test_evaluate_renders_selected_node_in_document
        expected = svg = <<~SVG
          <g id="xxx">
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
          </g>
        SVG
          .chomp

        actual = Derender.evaluate(svg, SVG(:minimal), id: "xxx").Render()

        assert_equal(expected, actual)
      end

      def test_evaluate_treats_kernel_names_as_elements
        each_collision_source do |name, text, svg, marker|
          actual = Derender.evaluate(svg, SVG(:minimal), id: "collision").Render()

          expected = <<~SVG
            <g id="collision">
              <#{name}>#{text.encode(xml: :text)}</#{name}>
            </g>
          SVG
            .chomp

          assert_equal(expected, actual)
          refute_path_exists(marker) if marker
        end
      end

      def test_evaluate_bang_appends_selected_node_to_document
        svg = <<~SVG
          <g id="xxx">
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
          </g>
        SVG
          .chomp

        expected = <<~SVG
          <svg>
            <line id="line1" length="10.0"/>
            <line id="line2" length="20.0"/>
          </svg>
        SVG
          .chomp

        actual = SVG(:minimal) do
          Derender.evaluate!(svg, self, id: "xxx")
        end
          .Render()

        assert_equal(expected, actual)
      end

      def test_evaluate_bang_treats_kernel_names_as_elements
        each_collision_source do |name, text, svg, marker|
          actual = SVG(:minimal) do
            Derender.evaluate!(svg, self, id: "collision")
          end
            .Render()

          expected = <<~SVG
            <svg>
              <#{name}>#{text.encode(xml: :text)}</#{name}>
            </svg>
          SVG
            .chomp

          assert_equal(expected, actual)
          refute_path_exists(marker) if marker
        end
      end

      def test_derender_file_converts_selected_node
        Dir.mktmpdir do |dir|
          file = ::File.join(dir, "source.svg")
          ::File.write(
            file,
            <<~SVG
              <g id="xxx">
                <line id="line1" length="10.0"/>
              </g>
            SVG
              .chomp
          )

          actual = Derender.derender_file(file, id: "xxx")

          expected = <<~SEVGI
            g id: "xxx" do
              line id: "line1", length: 10.0
            end
          SEVGI

          assert_equal(expected, actual)
        end
      end

      def test_include_treats_kernel_names_as_elements
        each_collision_file do |file, name, text, marker|
          actual = SVG(:minimal) { Include(file, "collision") }.Render()

          expected = <<~SVG
            <svg>
              <g id="collision">
                <#{name}>#{text.encode(xml: :text)}</#{name}>
              </g>
            </svg>
          SVG
            .chomp

          assert_equal(expected, actual)
          refute_path_exists(marker) if marker
        end
      end

      def test_include_children_treats_kernel_names_as_elements
        each_collision_file do |file, name, text, marker|
          actual = SVG(:minimal) { IncludeChildren(file, "collision") }.Render()

          expected = <<~SVG
            <svg>
              <#{name}>#{text.encode(xml: :text)}</#{name}>
            </svg>
          SVG
            .chomp

          assert_equal(expected, actual)
          refute_path_exists(marker) if marker
        end
      end

      def test_evaluate_file_bang_appends_selected_children
        Dir.mktmpdir do |dir|
          file = ::File.join(dir, "source.svg")
          ::File.write(
            file,
            <<~SVG
              <g id="xxx">
                <line id="line1" length="10.0"/>
                <line id="line2" length="20.0"/>
              </g>
            SVG
              .chomp
          )

          actual = SVG(:minimal) do
            Derender.evaluate_file!(file, self, id: "xxx")
          end
            .Render()

          expected = <<~SVG
            <svg>
              <line id="line1" length="10.0"/>
              <line id="line2" length="20.0"/>
            </svg>
          SVG
            .chomp

          assert_equal(expected, actual)
        end
      end

      def test_evaluate_preserves_direct_xml_shapes
        svg = <<~SVG
          <svg xmlns:xlink="http://www.w3.org/1999/xlink">
            <g id="chunk">
              <clip-path xlink:href="#clip">
                <text xml:space="preserve">  spaced  </text>
              </clip-path>
              <style>.mark { fill: red; }</style>
            </g>
          </svg>
        SVG
          .chomp

        actual = Derender.evaluate(svg, SVG(:minimal), id: "chunk").Render()

        expected = <<~SVG
          <g id="chunk">
            <clip-path xlink:href="#clip">
              <text xml:space="preserve">  spaced  </text>
            </clip-path>
            <style type="text/css">
              <![CDATA[
                .mark {
                  fill: red;
                }
              ]]>
            </style>
          </g>
        SVG
          .chomp

        assert_equal(expected, actual)
      end

      private

      def collision_source(name, text)
        <<~SVG
          <svg>
            <g id="collision">
              <#{name}>#{text}</#{name}>
            </g>
          </svg>
        SVG
          .chomp
      end

      def each_collision_file
        Dir.mktmpdir do |dir|
          COLLISION_ELEMENTS.each do |name, content|
            marker = name == "system" ? ::File.join(dir, "system-called") : nil
            text = content || "printf derender-system > #{marker}"
            file = ::File.join(dir, "#{name}.svg")

            ::File.write(file, collision_source(name, text))
            yield(file, name, text, marker)
          end
        end
      end

      def each_collision_source
        Dir.mktmpdir do |dir|
          COLLISION_ELEMENTS.each do |name, content|
            marker = name == "system" ? ::File.join(dir, "system-called") : nil
            text = content || "printf derender-system > #{marker}"

            yield(name, text, collision_source(name, text), marker)
          end
        end
      end
    end
  end
end
