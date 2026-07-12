# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Document
      class SymbolTest < Base
        document :symbol_test

        mixture :Symbols
      end
    end

    module Mixtures
      module IconSet
        extend(Graphics::Module)

        def first_icon
          rect(width: 1)
        end

        def second_icon
          circle(r: 2)
        end
      end

      class SymbolsTest < Minitest::Test
        def test_symbols_expands_public_module_methods
          expected = <<~SVG
            <svg>
              <defs id="IconSet">
                <symbol id="first-icon">
                  <title>First Icon</title>
                  <rect width="1"/>
                </symbol>
                <symbol id="second-icon">
                  <title>Second Icon</title>
                  <circle r="2"/>
                </symbol>
              </defs>
            </svg>
          SVG
            .chomp

          actual = SVG(:symbol_test) do
            Symbols(IconSet)
          end
            .Render()

          assert_equal(expected, actual)
        end

        def test_symbols_allows_custom_id_mapping
          actual = SVG(:symbol_test) do
            Symbols(IconSet, ids: -> (name) { "custom-#{name}" })
          end
            .Render()

          assert_match(/<symbol id="custom-first_icon">/, actual)
        end

        def test_symbols_renders_base_once_inside_defs
          mod = ::Module.new do
            extend(Graphics::Module)

            base { style(".shared {}") }

            def first = rect
            def second = circle
          end

          actual = SVG(:symbol_test) { Symbols(mod) }.Render()

          assert_equal(1, actual.scan("<style>").size)
          assert_operator(actual.index("<defs"), :<, actual.index("<style>"))
          assert_operator(actual.index("<style>"), :<, actual.index("<symbol"))
        end

        def test_symbols_separates_and_forwards_channels
          mod = ::Module.new do
            extend(Graphics::Module)

            base { style(".shared {}") }

            def icon(value, keyword:, &block)
              rect(id: "#{value}-#{keyword}-#{block.call}")
            end
          end

          result = nil
          doc = SVG(:symbol_test) do
            result = Symbols(
              mod,
              "argument",
              keyword: "keyword",
              attributes: {id: "catalog", class: "symbols"},
              ids: -> (name) { "mapped-#{name}" }
            ) { "block" }
          end

          assert_same(doc.children.first, result)
          assert_equal("catalog", result[:id])
          assert_equal("symbols", result[:class])
          assert_equal(%i[style symbol], result.children.map(&:name))
          assert_equal("mapped-icon", result.children.last[:id])
          assert_equal("argument-keyword-block", result.children.last.children.last[:id])
        end
      end
    end
  end
end
