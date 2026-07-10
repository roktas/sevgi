# frozen_string_literal: true

require "tmpdir"
require "yaml"

require_relative "../test_helper"

require "sevgi/showcase"

module Sevgi
  module Showcase
    class DarkTest < Minitest::Test
      ROOT = File.expand_path("../..", __dir__)

      def test_apply_replaces_quoted_and_percent_word_colors
        source = <<~RUBY
          COLORS = %w[#FF6961 #77DD77 #FFD700].freeze
          css ".cell" => { stroke: "white" }
        RUBY

        result = Dark.apply(
          source,
          {
            "#FF6961" => "#f27b72",
            "#77DD77" => "#7fdc9c",
            "#FFD700" => "#f1c95b",
            "white" => "#222"
          }
        )

        assert_includes(result, "%w[#f27b72 #7fdc9c #f1c95b]")
        assert_includes(result, "stroke: \"#222\"")
      end

      def test_apply_rejects_unapplied_mappings
        error = assert_raises(ArgumentError) { Dark.apply("fill: 'black'", {"yellow" => "purple"}) }

        assert_equal("Unapplied dark mapping(s): yellow", error.message)
      end

      def test_apply_file_preserves_source_mode
        Dir.mktmpdir do |dir|
          source = File.join(dir, "source.sevgi")
          target = File.join(dir, "target.sevgi")
          File.write(source, "fill: 'black'\n")
          File.chmod(0o744, source)

          Dark.apply_file(source, target, {"black" => "white"})

          assert_equal(0o744, File.stat(target).mode & 0o777)
        end
      end

      def test_light_showcase_copies_match_sources
        scripts.each do |name|
          assert_equal(read("srv/#{name}.sevgi"), read("doc/showcase/light/#{name}.sevgi"), name)
          assert_equal(read("srv/#{name}.svg"), read("doc/showcase/light/#{name}.svg"), name)
        end
      end

      def test_dark_showcase_sources_match_mappings
        scripts.each do |name|
          source = read("srv/#{name}.sevgi")
          mapping = dark_mapping(name)
          expected = mapping ? Dark.apply(source, mapping) : source

          assert_equal(expected, read("doc/showcase/dark/#{name}.sevgi"), name)
        end
      end

      def test_dark_showcase_svgs_match_sources
        Test::Suite.new(path("doc/showcase/dark")).valids.each do |script|
          result = script.run_passive

          assert_empty(result.err, script.name)
          assert_equal(File.read(script.svg).chomp, result.to_s, script.name)
        end
      end

      private

      def dark_mapping(name)
        file = path("srv/#{name}.yml")
        return unless File.exist?(file)

        YAML.load_file(file)&.fetch("dark", nil)
      end

      def path(relative) = File.join(ROOT, relative)

      def read(relative) = File.read(path(relative))

      def scripts
        Dir[path("srv/*.sevgi")].map { File.basename(it, ".sevgi") }.sort
      end
    end
  end
end
