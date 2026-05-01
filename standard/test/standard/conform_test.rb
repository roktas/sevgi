# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Standard
    class ConformTest < Minitest::Test
      def test_svg_element_basics
        assert(Conform.(:svg, attributes: %i[ viewBox ], elements: %i[ g ]))
      end

      def test_svg_element_gotcha_with_all_lowercase_viewbox
        assert_raises(InvalidAttributesError) do
          Conform.(:svg, attributes: %i[ viewbox ], elements: %i[ g ])
        end
      end

      def test_special_fe_diffuse_lighting
        assert(Conform.(:feDiffuseLighting, attributes: %i[ surfaceScale ], elements: %i[ desc fePointLight ]))

        assert_raises(UnallowedElementsError) do
          Conform.(:feDiffuseLighting, attributes: %i[ surfaceScale ], elements: %i[ desc g fePointLight ])
        end
      end
    end
  end
end
