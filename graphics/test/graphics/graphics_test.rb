# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Graphics
    class GraphicsTest < Minitest::Test
      def test_svg_constant_aliases_graphics
        assert(SVG.is_a?(::Module))
        assert_equal(SVG, Graphics)
      end

      def test_graphics_responds_to_public_helpers
        %i[
          SVG
          canvas
          document
          paper
          paper!
        ].each do |method|
          assert_respond_to(Graphics, method)
        end
      end

      def test_graphics_loads_nokogiri_before_native_export_libraries
        skip("Nokogiri is not loaded") unless defined?(::Nokogiri)

        libxml = ::Nokogiri::VERSION_INFO.fetch("libxml")

        assert_empty(::Nokogiri::VERSION_INFO.fetch("warnings"))
        assert_equal(libxml.fetch("compiled"), libxml.fetch("loaded"))
      end

      def test_canvas_returns_canvas_instance
        canvas = Graphics.canvas(width: 3, height: 5)
        assert_instance_of(Graphics::Canvas, canvas)
      end

      def test_document_returns_document_class
        doc = Graphics.document(:foo)
        assert(doc < Graphics::Document::Base)
      end

      def test_paper_returns_profile_name
        paper = Graphics.paper(3, 5, :xyz)
        assert_equal(:xyz, paper)
      end

      def test_paper_bang_returns_profile_name
        paper = Graphics.paper!(3, 5, :abc)
        assert_equal(:abc, paper)
      end
    end
  end
end
