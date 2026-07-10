# frozen_string_literal: true

require "open3"
require "rbconfig"
require "rubygems/package"

require_relative "../test_helper"

module Sevgi
  module Sundries
    class StandaloneTest < Minitest::Test
      ROOT = ::File.expand_path("../../..", __dir__)
      INTERNAL = {
        "sevgi-function" => "function",
        "sevgi-geometry" => "geometry",
        "sevgi-graphics" => "graphics"
      }.freeze
      SOURCE_LOAD_PATHS = [*INTERNAL.values, "sundries"].map { ::File.join(ROOT, it, "lib") }.freeze
      CLEAN_ENV = {
        "BUNDLE_BIN_PATH" => nil,
        "BUNDLE_GEMFILE" => nil,
        "GEM_HOME" => nil,
        "GEM_PATH" => nil,
        "RUBYLIB" => nil,
        "RUBYOPT" => nil
      }.freeze

      def test_entrypoint_loads_eager_surfaces
        assert_ruby(
          SOURCE_LOAD_PATHS,
          <<~RUBY
            require "sevgi/sundries"
            raise "loaded aggregate sevgi" if defined?(::SVG)

            tile = Sevgi::Sundries::Tile.new(Sevgi::Geometry::Rect[3, 5])
            ruler = Sevgi::Sundries::Ruler.new(unit: 1, multiple: 1, brut: 3)
            grid = Sevgi::Sundries::Grid[ruler, ruler]

            raise "bad tile" unless Sevgi::F.eq?(tile.box.width, 3)
            raise "bad canvas" unless grid.canvas.is_a?(Sevgi::Graphics::Canvas)
          RUBY
        )
      end

      def test_package_smokes_declared_dependencies
        Dir.mktmpdir do |dir|
          packages = build_packages(dir)
          dependencies = runtime_dependency_names(packages.fetch("sevgi-sundries"))

          INTERNAL.each_key { assert_includes(dependencies, it) }
          refute_includes(dependencies, "sevgi")

          load_paths = packaged_load_paths(packages, dependencies, dir)
          assert_ruby(load_paths, non_native_smoke, disable_gems: true)
        end
      end

      private

      def build_packages(dir)
        [*INTERNAL.values, "sundries"].to_h do |component|
          package = "sevgi-#{component}"
          [package, build_package(component, dir)]
        end
      end

      def build_package(component, dir)
        package = "sevgi-#{component}"
        component_dir = ::File.join(ROOT, component)
        path = ::File.join(dir, "#{package}.gem")

        capture_io do
          Dir.chdir(component_dir) do
            spec = ::Gem::Specification.load("#{package}.gemspec")
            ::Gem::Package.build(spec, true, false, path)
          end
        end

        path
      end

      def runtime_dependency_names(package)
        ::Gem::Package.new(package).spec.runtime_dependencies.map(&:name)
      end

      def packaged_load_paths(packages, dependencies, dir)
        dependencies
          .intersection(INTERNAL.keys)
          .map { package_load_path(packages.fetch(it), dir) }
          .push(package_load_path(packages.fetch("sevgi-sundries"), dir))
      end

      def package_load_path(package, dir)
        target = ::File.join(dir, ::File.basename(package, ".gem"))
        ::FileUtils.mkdir_p(target)
        ::Gem::Package.new(package).extract_files(target)
        ::File.join(target, "lib")
      end

      def assert_ruby(load_paths, code, disable_gems: false)
        args = [RbConfig.ruby]
        args << "--disable-gems" if disable_gems
        load_paths.each { args.push("-I", it) }
        args.push("-e", code)

        out, err, status = Open3.capture3(*(disable_gems ? [CLEAN_ENV] : []), *args)

        assert(status.success?, "stdout:\n#{out}\nstderr:\n#{err}")
      end

      def non_native_smoke
        <<~RUBY
          require "sevgi/function"
          require "sevgi/geometry"
          require "sevgi/graphics"
          require "sevgi/sundries/ruler"
          require "sevgi/sundries/tile"
          require "sevgi/sundries/grid"

          tile = Sevgi::Sundries::Tile.new(Sevgi::Geometry::Rect[3, 5])
          ruler = Sevgi::Sundries::Ruler.new(unit: 1, multiple: 1, brut: 3)
          grid = Sevgi::Sundries::Grid[ruler, ruler]

          raise "bad tile" unless Sevgi::F.eq?(tile.box.height, 5)
          raise "bad grid" unless grid.canvas.is_a?(Sevgi::Graphics::Canvas)
        RUBY
      end
    end
  end
end
