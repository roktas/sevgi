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
            Symbols(IconSet) { |name| "custom-#{name}" }
          end
            .Render()

          assert_match(/<symbol id="custom-first_icon">/, actual)
        end
      end
    end
  end
end
