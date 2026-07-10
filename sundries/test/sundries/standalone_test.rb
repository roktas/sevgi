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
        "GEM_HOST_API_KEY" => nil,
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
          %w[cairo hexapdf rsvg2].each { refute_includes(dependencies, it) }
          refute_includes(dependencies, "sevgi")

          load_paths = packaged_load_paths(packages, dependencies, dir)
          assert_ruby(load_paths, non_native_smoke, disable_gems: true)
        end
      end

      def test_package_reports_missing_native_export_gems
        Dir.mktmpdir do |dir|
          packages = build_packages(dir)
          dependencies = runtime_dependency_names(packages.fetch("sevgi-sundries"))
          load_paths = packaged_load_paths(packages, dependencies, dir)

          assert_ruby(load_paths, missing_native_smoke, disable_gems: true)
        end
      end

      def test_package_exports_with_optional_native_gems
        Dir.mktmpdir do |dir|
          packages = build_packages(dir)
          dependencies = runtime_dependency_names(packages.fetch("sevgi-sundries"))
          load_paths = packaged_load_paths(packages, dependencies, dir)

          assert_ruby(load_paths, native_export_smoke, env: optional_gem_env)
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

      def assert_ruby(load_paths, code, disable_gems: false, clean: disable_gems, env: clean ? clean_env : nil)
        args = [RbConfig.ruby]
        args << "--disable-gems" if disable_gems
        load_paths.each { args.push("-I", it) }
        args.push("-e", code)

        out, err, status = Open3.capture3(*(env ? [env] : []), *args)

        assert(status.success?, "stdout:\n#{out}\nstderr:\n#{err}")
      end

      def clean_env = CLEAN_ENV.merge(ENV.keys.grep(/\ABUNDLE|BUNDLER/).to_h { [it, nil] })

      def optional_gem_env
        clean_env.merge(
          "GEM_HOME" => ENV["GEM_HOME"] || Gem.dir,
          "GEM_PATH" => Gem.path.join(::File::PATH_SEPARATOR)
        )
      end

      def missing_native_smoke
        <<~RUBY
          require "sevgi/sundries"

          begin
            Sevgi::Sundries::Export.call(%(<svg width="1" height="1"/>), "/tmp/out.png")
          rescue Sevgi::MissingComponentError => error
            raise "wrong message: \#{error.message}" unless error.message.include?("cairo")
          else
            raise "native export did not report missing optional gems"
          end
        RUBY
      end

      def non_native_smoke
        <<~RUBY
          require "sevgi/sundries"
          require "sevgi/function"
          require "sevgi/geometry"
          require "sevgi/graphics"
          require "sevgi/sundries/ruler"
          require "sevgi/sundries/tile"
          require "sevgi/sundries/grid"

          raise "loaded Cairo" if defined?(::Cairo)
          raise "loaded HexaPDF" if defined?(::HexaPDF)
          raise "loaded RSVG" if defined?(::Rsvg)

          tile = Sevgi::Sundries::Tile.new(Sevgi::Geometry::Rect[3, 5])
          ruler = Sevgi::Sundries::Ruler.new(unit: 1, multiple: 1, brut: 3)
          grid = Sevgi::Sundries::Grid[ruler, ruler]

          raise "bad tile" unless Sevgi::F.eq?(tile.box.height, 5)
          raise "bad grid" unless grid.canvas.is_a?(Sevgi::Graphics::Canvas)
        RUBY
      end

      def native_export_smoke
        <<~RUBY
          require "tmpdir"
          require "sevgi/sundries/export"

          Dir.mktmpdir do |dir|
            output = File.join(dir, "out.png")
            result = Sevgi::Sundries::Export.call(%(<svg width="1" height="1"/>), output)

            raise "bad result" unless result == output
            raise "missing output" unless File.size?(output)
          end
        RUBY
      end
    end
  end
end
