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

      def test_conversions_reject_malformed_xml
        target = SVG(:minimal)

        [
          -> { Derender.decompile("<svg>") },
          -> { Derender.derender("<svg>") },
          -> { Derender.evaluate("<svg>", target) }
        ].each do |conversion|
          assert_raises(ArgumentError, &conversion)
        end
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

      def test_evaluate_returns_included_current_element
        svg = <<~SVG
          <g id="xxx">
            <line id="line1" length="10.0"/>
          </g>
        SVG
          .chomp
        target = SVG(:minimal)

        actual = Derender.evaluate(svg, target, id: "xxx")

        assert_same(target.children.first, actual)
        assert_equal("xxx", actual[:id])
      end

      def test_evaluate_accepts_a_raw_graphics_element_parent
        target = Graphics::Element.root

        actual = Derender.evaluate("<g id=\"raw\"><line/></g>", target)

        assert_same(target.children.first, actual)
        assert_equal(:g, actual.name)
        assert_equal(:line, actual.children.first.name)
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

      def test_evaluate_children_appends_selected_children
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

        target = SVG(:minimal)
        returned = Derender.evaluate_children(svg, target, id: "xxx")
        actual = target.Render()

        assert_equal(expected, actual)
        assert_equal(%i[line line], returned.map(&:name))
        assert_predicate(returned, :frozen?)
      end

      def test_evaluate_children_treats_kernel_names_as_elements
        each_collision_source do |name, text, svg, marker|
          actual = SVG(:minimal) do
            Derender.evaluate_children(svg, self, id: "collision")
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

      def test_evaluate_file_returns_included_current_element
        Dir.mktmpdir do |dir|
          file = ::File.join(dir, "source.svg")
          ::File.write(file, "<g id=\"xxx\"><line id=\"line1\"/></g>")
          target = SVG(:minimal)

          actual = Derender.evaluate_file(file, target, id: "xxx")

          assert_same(target.children.first, actual)
          assert_equal("xxx", actual[:id])
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

      def test_evaluate_children_file_appends_selected_children
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

          target = SVG(:minimal)
          returned = Derender.evaluate_children_file(file, target, id: "xxx")
          actual = target.Render()

          expected = <<~SVG
            <svg>
              <line id="line1" length="10.0"/>
              <line id="line2" length="20.0"/>
            </svg>
          SVG
            .chomp

          assert_equal(expected, actual)
          assert_equal(%i[line line], returned.map(&:name))
          assert_predicate(returned, :frozen?)
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
          <g id="chunk" xmlns:xlink="http://www.w3.org/1999/xlink">
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

      def test_derender_selected_node_preserves_namespace_scope
        svg = <<~SVG
          <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
            <g id="chunk">
              <use xlink:href="#shape"/>
            </g>
          </svg>
        SVG
          .chomp

        actual = Derender.derender(svg, id: "chunk")

        expected = <<~SEVGI
          g id: "chunk", xmlns: "http://www.w3.org/2000/svg", "xmlns:xlink": "http://www.w3.org/1999/xlink" do
            use "xlink:href": "#shape"
          end
        SEVGI

        assert_equal(expected, actual)
      end

      def test_derender_preserves_qualified_element_names
        svg = <<~SVG
          <svg xmlns:mark="https://example.test/mark">
            <mark:shape mark:value="x"/>
          </svg>
        SVG
          .chomp

        actual = Derender.derender(svg)

        expected = <<~SEVGI
          SVG "xmlns:mark": "https://example.test/mark" do
            Element(:"mark:shape", "mark:value": "x")
          end
        SEVGI

        assert_equal(expected, actual)
      end

      def test_evaluate_preserves_qualified_element_names
        svg = <<~SVG
          <svg xmlns:mark="https://example.test/mark">
            <mark:shape mark:value="x"/>
          </svg>
        SVG
          .chomp

        actual = Derender.evaluate(svg, SVG(:minimal)).Render()

        expected = <<~SVG
          <svg xmlns:mark="https://example.test/mark">
            <mark:shape mark:value="x"/>
          </svg>
        SVG
          .chomp

        assert_equal(expected, actual)
      end

      def test_evaluate_selected_node_preserves_namespace_scope
        svg = <<~SVG
          <svg xmlns:xlink="http://www.w3.org/1999/xlink">
            <g id="chunk">
              <use xlink:href="#shape"/>
            </g>
          </svg>
        SVG
          .chomp

        actual = Derender.evaluate(svg, SVG(:minimal), id: "chunk").Render()

        expected = <<~SVG
          <g id="chunk" xmlns:xlink="http://www.w3.org/1999/xlink">
            <use xlink:href="#shape"/>
          </g>
        SVG
          .chomp

        assert_equal(expected, actual)
      end

      def test_namespace_dispatch_round_trips_foreign_nodes
        xml = <<~SVG
          <svg xmlns="http://www.w3.org/2000/svg" xmlns:f="urn:foreign" xmlns:q="urn:qualified">
            <f:style xmlns:m="urn:meta" q:kind="style" m:local="yes" xml:space="preserve">  raw style  </f:style>
            <f:svg q:kind="svg">
              <f:item/>
            </f:svg>
            <group xmlns="urn:foreign">
              <style xml:space="preserve">  default style  </style>
              <svg q:kind="nested">
                <item/>
              </svg>
            </group>
            <svg id="nested-svg">
              <circle/>
            </svg>
          </svg>
        SVG
          .chomp

        generated = instance_eval(Derender.derender(xml), "generated.sevgi").Render()
        evaluated = Derender.evaluate(xml, SVG(:minimal)).Render()

        assert_xml_tree_equal(xml, generated)
        assert_xml_tree_equal(xml, evaluated)
      end

      def test_derender_child_node_preserves_local_namespace
        svg = <<~SVG
          <svg>
            <g id="chunk" xmlns:mark="https://example.test/mark">
              <use mark:href="#shape"/>
            </g>
          </svg>
        SVG
          .chomp

        actual = Derender.derender(svg)

        expected = <<~SEVGI
          SVG do
            g id: "chunk", "xmlns:mark": "https://example.test/mark" do
              use "mark:href": "#shape"
            end
          end
        SEVGI

        assert_equal(expected, actual)
      end

      private

      def assert_xml_tree_equal(expected, actual)
        expected = Nokogiri::XML(expected, &:strict).root
        actual = Nokogiri::XML(actual, &:strict).root

        assert_equal(xml_signature(expected), xml_signature(actual))
      end

      def xml_signature(node)
        [xml_name(node), xml_declarations(node), xml_attributes(node), xml_children(node)]
      end

      def xml_attributes(node)
        node
          .attribute_nodes
          .map { [[it.namespace&.prefix, it.namespace&.href, it.name], it.value] }
          .sort_by { it.flatten.map(&:to_s) }
      end

      def xml_child(node)
        return xml_signature(node) if node.element?
        [:text, node.text] if (node.text? || node.cdata?) && !node.text.strip.empty?
      end

      def xml_children(node) = node.children.filter_map { xml_child(it) }

      def xml_declarations(node)
        node.namespace_definitions.map { [it.prefix, it.href] }.sort_by { it.map(&:to_s) }
      end

      def xml_name(node) = [node.namespace&.prefix, node.namespace&.href, node.name]

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
