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

        def test_ancestral_merges_internal_attributes
          descendant = nil

          SVG(DOC, _: {page: "one"}) do
            g(_: {group: "main"}) do
              descendant = rect(_: {shape: "box"})
            end
          end

          assert_equal({page: "one", group: "main", shape: "box"}, descendant.Ancestral())
        end
      end
    end
  end
end
