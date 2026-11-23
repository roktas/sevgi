# frozen_string_literal: true

require "open3"
require "rbconfig"
require "tmpdir"

require_relative "../test_helper"

module RuboCop
  module Sevgi
    class PluginTest < Minitest::Test
      def test_plugin_describes_rules
        plugin = Plugin.new({})
        context = LintRoller::Context.new(engine: :rubocop, engine_version: RuboCop::Version.version)

        assert_equal("sevgi-appendix", plugin.about.name)
        assert(plugin.supported?(context))
        assert_path_exists(plugin.rules(context).value)
      end

      def test_plugin_accepts_dsl_style
        status, output, source = inspect_source(
          <<~SEVGI
            opacity = values.fetch(0)
            known = const_defined?(:MARK)
            (0..10).step(2) { |x| points << x }

            SVG :minimal do
              defs { path id: "mark", d: "M0 0" }
              rect width: 4, height: 4
            end

            SVG(:minimal) { circle r: 4 }.Render
          SEVGI
        )

        assert_equal(0, status, output)
        assert_includes(output, "no offenses detected")
        assert_includes(source, "SVG(:minimal) { circle r: 4 }.Render")
      end

      def test_plugin_corrects_dsl_style
        status, output, source = inspect_source(
          <<~SEVGI,
            SVG(:minimal) {
              rect(width: 4, height: 4, fill: 'red')
            }
          SEVGI
          autocorrect: true
        )

        assert_equal(0, status, output)
        assert_equal(
          <<~SEVGI,
            SVG :minimal do
              rect width: 4, height: 4, fill: "red"
            end
          SEVGI
          source
        )
      end

      def test_plugin_autocorrects_without_style_conflicts
        lib = File.expand_path("../../../lib", __dir__)

        Dir.mktmpdir do |dir|
          file = File.join(dir, "drawing.sevgi")
          config = File.join(dir, ".rubocop.yml")
          File.write(config, "AllCops:\n  NewCops: enable\nplugins:\n  - sevgi-appendix\n")
          File.write(
            file,
            <<~SEVGI
              # frozen_string_literal: true

              SVG(:minimal) {
                rect(width: 4, height: 4, fill: 'red')
              }
            SEVGI
          )

          out, err, status = Open3.capture3(
            RbConfig.ruby,
            "-I#{lib}",
            "-rrubocop",
            "-e",
            "exit(RuboCop::CLI.new.run(ARGV))",
            "--",
            "drawing.sevgi",
            "--config",
            ".rubocop.yml",
            "--autocorrect-all",
            "--format",
            "simple",
            "--cache",
            "false",
            chdir: dir
          )
          output = "#{out}#{err}"

          assert_predicate(status, :success?, output)
          refute_includes(output, "Infinite loop detected")
          assert_equal(
            <<~SEVGI,
              # frozen_string_literal: true

              SVG :minimal do
                rect width: 4, height: 4, fill: "red"
              end
            SEVGI
            File.read(file)
          )
        end
      end

      private

      def inspect_source(source, autocorrect: false)
        Dir.mktmpdir do |dir|
          file = File.join(dir, "drawing.sevgi")
          config = File.join(dir, ".rubocop.yml")
          File.write(file, source)
          File.write(config, "AllCops:\n  NewCops: enable\nplugins:\n  - sevgi-appendix\n")

          args = [file, "--config", config, "--only", "Sevgi", "--format", "simple", "--cache", "false"]
          args << "--autocorrect-all" if autocorrect
          status = nil
          output, error = capture_io { status = RuboCop::CLI.new.run(args) }

          [status, "#{output}#{error}", File.read(file)]
        end
      end
    end
  end
end
