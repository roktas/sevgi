# frozen_string_literal: true

require "fileutils"
require "rbconfig"
require "tmpdir"

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

      def test_mixtures_keep_private_surface_small
        expected = [
          [:Call, [:CallWithin], []],
          [:Core, [], []],
          [:Duplicate, [], []],
          [:Export, [:Export], []],
          [:Hatch, [], []],
          [:Identify, [], []],
          [:Include, [], []],
          [:Inkscape, [], []],
          [:Lint, [], []],
          [:Polyfills, [], []],
          [:RDF, [], []],
          [:Render, [], []],
          [:Save, [], []],
          [:Symbols, [], []],
          [:Tile, [], []],
          [:Transform, [], []],
          [:Underscore, [], []],
          [:Validate, [], []],
          [:Wrappers, [], []]
        ]

        actual = expected.map do |name, _private_methods, _protected_methods|
          mod = Graphics::Mixtures.const_get(name)

          [name, mod.private_instance_methods(false).sort, mod.protected_instance_methods(false).sort]
        end

        assert_equal(expected, actual)
      end

      def test_graphics_loads_nokogiri_before_native_export_libraries
        skip("Nokogiri is not loaded") unless defined?(::Nokogiri)

        libxml = ::Nokogiri::VERSION_INFO.fetch("libxml")

        assert_empty(::Nokogiri::VERSION_INFO.fetch("warnings"))
        assert_equal(libxml.fetch("compiled"), libxml.fetch("loaded"))
      end

      def test_graphics_loads_without_standard_component
        Dir.mktmpdir do |dir|
          FileUtils.mkdir_p(File.join(dir, "sevgi"))
          File.write(File.join(dir, "sevgi", "standard.rb"), "raise LoadError, 'blocked standard'\n")

          function = ::File.expand_path("../../../function/lib", __dir__)
          graphics = ::File.expand_path("../../lib", __dir__)
          result = Function.sh(
            {"BUNDLE_GEMFILE" => nil, "RUBYLIB" => nil, "RUBYOPT" => nil},
            RbConfig.ruby,
            "-I#{dir}",
            "-I#{function}",
            "-I#{graphics}",
            "-e",
            "require 'sevgi/graphics'; puts Sevgi::Graphics::Element.valid?(:custom_tag)"
          )

          assert(result.ok?, result.err)
          assert_equal("true", result.outline)
        end
      end

      def test_hatch_reports_missing_geometry_component
        Dir.mktmpdir do |dir|
          FileUtils.mkdir_p(File.join(dir, "sevgi"))
          File.write(File.join(dir, "sevgi", "geometry.rb"), "raise LoadError, 'blocked geometry'\n")

          function = ::File.expand_path("../../../function/lib", __dir__)
          graphics = ::File.expand_path("../../lib", __dir__)
          result = Function.sh(
            {"BUNDLE_GEMFILE" => nil, "RUBYLIB" => nil, "RUBYOPT" => nil},
            RbConfig.ruby,
            "-I#{dir}",
            "-I#{function}",
            "-I#{graphics}",
            "-e",
            <<~RUBY
              require 'sevgi/graphics'
              include Sevgi::Graphics
              begin
                SVG(:inkscape).Hatch(nil, angle: 0, step: 1)
              rescue NoMethodError => error
                puts error.message
              end
            RUBY
          )

          assert(result.ok?, result.err)
          assert_match(%r{sevgi/geometry}, result.out)
        end
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
        paper = Graphics.paper(3, 5, :graphics_test_paper)
        assert_equal(:graphics_test_paper, paper)
      end

      def test_paper_bang_returns_profile_name
        paper = Graphics.paper!(3, 5, :graphics_test_paper_bang)
        assert_equal(:graphics_test_paper_bang, paper)
      end

      def test_paper_preserves_existing_profile
        original = Paper.a4

        Graphics.paper(3, 5, :a4)

        assert_equal(original, Paper.a4)
      end

      def test_paper_bang_overwrites_existing_profile
        Graphics.paper!(3, 5, :graphics_test_overwrite)
        Graphics.paper!(7, 11, :graphics_test_overwrite)

        assert_equal([7.0, 11.0, :mm, :graphics_test_overwrite], Paper.graphics_test_overwrite.deconstruct)
      end
    end
  end
end
