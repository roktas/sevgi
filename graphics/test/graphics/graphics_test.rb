# frozen_string_literal: true

require "fileutils"
require "rbconfig"
require "tmpdir"

require_relative "../test_helper"

module Sevgi
  module Graphics
    class GraphicsTest < Minitest::Test
      class Phases
        def initialize(parties)
          @parties = parties
          @counts = Hash.new(0)
          @condition = ConditionVariable.new
          @mutex = Mutex.new
        end

        def wait(phase)
          @mutex.synchronize do
            @counts[phase] += 1
            @condition.broadcast if @counts[phase] == @parties
            @condition.wait(@mutex) while @counts[phase] < @parties
          end
        end
      end

      class Name
        def initialize(name, phases)
          @name = name
          @phase = 0
          @phases = phases
        end

        def to_sym
          @phase += 1
          @phases.wait(@phase)
          @name
        end
      end

      private_constant :Name, :Phases

      def test_svg_constant_aliases_graphics
        assert(SVG.is_a?(::Module))
        assert_equal(SVG, Graphics)
      end

      def test_graphics_responds_to_public_helpers
        %i[
          SVG
          canvas
          document
          document!
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
        result = run_without("standard", "require 'sevgi/graphics'; puts Sevgi::Graphics::Element.valid?(:custom_tag)")

        assert(result.ok?, result.err)
        assert_equal("true", result.outline)
      end

      def test_graphics_propagates_standard_dependency_load_error
        result = run_with_load_error("standard", "nested/dependency", "require 'sevgi/graphics'")

        refute(result.ok?)
        assert_match(%r{nested/dependency}, result.err)
      end

      def test_hatch_reports_missing_geometry_component
        result = run_without(
          "geometry",
          <<~RUBY
            require 'sevgi/graphics'
            include Sevgi::Graphics
            begin
              SVG(:inkscape).Hatch(nil, angle: 0, step: 1)
            rescue Sevgi::MissingComponentError => error
              puts [error.class, error.message].join(": ")
            end
          RUBY
        )

        assert(result.ok?, result.err)
        assert_match(/Sevgi::MissingComponentError/, result.out)
        assert_match(%r{sevgi/geometry}, result.out)
      end

      def test_hatch_propagates_geometry_dependency_load_error
        result = run_with_load_error(
          "geometry",
          "nested/dependency",
          <<~RUBY
            require 'sevgi/graphics'
            include Sevgi::Graphics
            SVG(:inkscape).Hatch(nil, angle: 0, step: 1)
          RUBY
        )

        refute(result.ok?)
        assert_match(%r{nested/dependency}, result.err)
      end

      def test_export_reports_missing_sundries_component
        result = run_without(
          "sundries",
          <<~RUBY
            require 'sevgi/graphics'
            include Sevgi::Graphics
            begin
              SVG(:minimal).PDF('/tmp/out.pdf')
            rescue Sevgi::MissingComponentError => error
              puts [error.class, error.message].join(": ")
            end
          RUBY
        )

        assert(result.ok?, result.err)
        assert_match(/Sevgi::MissingComponentError/, result.out)
        assert_match(%r{sevgi/sundries}, result.out)
      end

      def test_export_propagates_sundries_dependency_load_error
        result = run_with_load_error(
          "sundries",
          "nested/dependency",
          <<~RUBY
            require 'sevgi/graphics'
            include Sevgi::Graphics
            SVG(:minimal).PDF('/tmp/out.pdf')
          RUBY
        )

        refute(result.ok?)
        assert_match(%r{nested/dependency}, result.err)
      end

      def test_include_reports_missing_derender_component
        result = run_without(
          "derender",
          <<~RUBY
            require 'sevgi/graphics'
            include Sevgi::Graphics
            begin
              SVG(:minimal).Include('source.svg', 'id')
            rescue Sevgi::MissingComponentError => error
              puts [error.class, error.message].join(": ")
            end
          RUBY
        )

        assert(result.ok?, result.err)
        assert_match(/Sevgi::MissingComponentError/, result.out)
        assert_match(%r{sevgi/derender}, result.out)
      end

      def test_include_propagates_derender_dependency_load_error
        result = run_with_load_error(
          "derender",
          "nested/dependency",
          <<~RUBY
            require 'sevgi/graphics'
          RUBY
        )

        refute(result.ok?)
        assert_match(%r{nested/dependency}, result.err)
      end

      def test_canvas_returns_canvas_instance
        canvas = Graphics.canvas(width: 3, height: 5)
        assert_instance_of(Graphics::Canvas, canvas)
      end

      def test_document_returns_document_class
        doc = Graphics.document(:foo, attributes: {})
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

        Graphics.paper(original.width, original.height, :a4, unit: original.unit)

        assert_equal(original, Paper.a4)
      end

      def test_paper_rejects_conflicting_profile
        error = assert_raises(ArgumentError) { Graphics.paper(3, 5, :a4) }

        assert_match(/\ba4\b/, error.message)
      end

      def test_paper_race_rejects_conflicting_profile
        name = :graphics_paper_race
        successes, failures = racing_papers(name, [3, 7]).partition { |_, result| !result.is_a?(::Exception) }
        registered = Paper.public_send(name)

        assert_equal(1, successes.size)
        assert_equal([Sevgi::ArgumentError], failures.map { |_, result| result.class })
        assert_equal([registered.width], successes.map { |width, _| width.to_f })
      end

      def test_paper_race_keeps_matching_profile
        name = :graphics_paper_same_race
        results = racing_papers(name, [3, 3])

        refute(results.any? { |_, result| result.is_a?(::Exception) })
        assert_equal([3.0, 5.0, :mm, name], Paper.public_send(name).deconstruct)
      end

      def test_paper_bang_overwrites_existing_profile
        Graphics.paper!(3, 5, :graphics_test_overwrite)
        Graphics.paper!(7, 11, :graphics_test_overwrite)

        assert_equal([7.0, 11.0, :mm, :graphics_test_overwrite], Paper.graphics_test_overwrite.deconstruct)
      end

      private

      def racing_papers(name, widths)
        phases = Phases.new(widths.size)
        widths
          .map do |width|
            Thread.new do
              input = Name.new(name, phases)
              [width, Graphics.paper(width, 5, input)]
            rescue ::StandardError => e
              [width, e]
            end
          end
          .map(&:value)
      end

      def run_with_load_error(component, path, script)
        Dir.mktmpdir do |dir|
          FileUtils.mkdir_p(File.join(dir, "sevgi"))
          File.write(
            File.join(dir, "sevgi", "#{component}.rb"),
            <<~RUBY
              error = LoadError.new(#{path.inspect})
              error.instance_variable_set(:@path, #{path.inspect})
              raise error
            RUBY
          )

          function = ::File.expand_path("../../../function/lib", __dir__)
          graphics = ::File.expand_path("../../lib", __dir__)

          Function.sh(
            {"BUNDLE_GEMFILE" => nil, "RUBYLIB" => nil, "RUBYOPT" => nil},
            RbConfig.ruby,
            "-I#{dir}",
            "-I#{function}",
            "-I#{graphics}",
            "-e",
            script
          )
        end
      end

      def run_without(component, script) = run_with_load_error(component, "sevgi/#{component}", script)
    end
  end
end
