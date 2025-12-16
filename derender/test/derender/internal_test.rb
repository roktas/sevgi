# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Derender
    module CSS
      class CSSTest < Minitest::Test
        def test_css
          css = <<~'CSS'.chomp
            * {
              overflow: visible;
            }
            .code {
              font-weight: 300;
              font-size: 2.5px;
              font-family: Operator Mono Lig;
              letter-spacing: 0;
              fill: #1a1a1a;
              stroke-width: 0.264583;
            }
            #Tile {
              stroke: #606060;
              stroke-width: 0.32;
              stroke-linejoin: round;
              fill: darkgray;
              fill-opacity: 0.4;
            }
          CSS

          actual = Derender::CSS.to_hash(css)

          expected = {
            "*"     => {
              "overflow" => "visible"
            },
            ".code" => {
              "font-weight"    => "300",
              "font-size"      => "2.5px",
              "font-family"    => "Operator Mono Lig",
              "letter-spacing" => "0",
              "fill"           => "#1a1a1a",
              "stroke-width"   => "0.264583"
            },
            "#Tile" => {
              "stroke"          => "#606060",
              "stroke-width"    => "0.32",
              "stroke-linejoin" => "round",
              "fill"            => "darkgray",
              "fill-opacity"    => "0.4"
            }
          }

          assert_equal(expected, actual)
        end
      end
    end
  end
end
