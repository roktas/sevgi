# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Graphics
    class GraphicsTest < Minitest::Test
      def test_svg_is_graphics
        assert(SVG.is_a?(::Module))
        assert_equal(SVG, Graphics)
      end

      def test_graphics_interface
        %i[
          SVG
          canvas
          document
          paper
          paper!
        ].each do
          assert_respond_to(Graphics, it)
        end
      end

      def test_graphics_graphics_canvas
        canvas = Graphics.canvas(width: 3, height: 5)
        assert_instance_of(Graphics::Canvas, canvas)
      end

      def test_graphics_graphics_doc
        doc = Graphics.document(:foo)
        assert(doc < Graphics::Document::Base)
      end

      def test_graphics_graphics_paper
        paper = Graphics.paper(3, 5, :xyz)
        assert_equal(:xyz, paper)
      end

      def test_graphics_graphics_paper_bang
        paper = Graphics.paper!(3, 5, :abc)
        assert_equal(:abc, paper)
      end
    end
  end
end
