# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class UnderscoreTest < Minitest::Test
        DOC = :minimal

        def test_underscore_appends_text_content
          expected = <<~SVG
            <svg>
              <text>
                You are
                <tspan>not</tspan>
                a banana
              </text>
            </svg>
          SVG
            .chomp

          actual = SVG(DOC) do
            text do
              _("You are")
              tspan("not")
              _("a banana")
            end
          end
            .Render()

          assert_equal(expected, actual)
        end

        def test_comment_appends_xml_comment
          expected = <<~SVG
            <svg>
              <text>
                <!-- FOO -->
                You are
                <tspan>not</tspan>
                a banana
              </text>
            </svg>
          SVG
            .chomp

          actual = SVG(DOC) do
            text do
              Comment("FOO")
              _("You are")
              tspan("not")
              _("a banana")
            end
          end
            .Render()

          assert_equal(expected, actual)
        end

        def test_comment_rejects_invalid_xml_bodies
          assert_raises(ArgumentError) { SVG(DOC) { Comment("a -- b") } }
          assert_raises(ArgumentError) { SVG(DOC) { Comment("trailing-") } }
          assert_raises(ArgumentError) { SVG(DOC) { Comment("invalid\u0000") } }
        end

        def test_ancestral_merges_internal_attributes
          descendant = nil

          SVG(DOC, _: {page: "one"}) do
            g(_: {group: "main"}) do
              descendant = rect(_: {shape: "box"})
            end
          end

          assert_equal({page: "one", group: "main", shape: "box"}, descendant.Ancestral())
        end

        def test_ancestral_uses_only_ancestor_chain
          descendant = nil

          SVG(DOC, _: {root: "root", shared: "root"}) do
            g(_: {sibling: "sibling", shared: "sibling"}) do
              rect(_: {niece: "niece", shared: "niece"})
            end

            g(_: {ancestor: "ancestor", shared: "ancestor"}) do
              descendant = rect(_: {self: "self", shared: "self"})
            end
          end

          assert_equal(
            {root: "root", ancestor: "ancestor", self: "self", shared: "self"},
            descendant.Ancestral()
          )
        end
      end
    end
  end
end
