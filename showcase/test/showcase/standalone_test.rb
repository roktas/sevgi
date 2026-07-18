# frozen_string_literal: true

require "open3"
require "rbconfig"

require_relative "../test_helper"

module Sevgi
  module Showcase
    class StandaloneTest < Minitest::Test
      def test_showcase_support_is_explicit_and_standalone
        script = <<~RUBY
          require "sevgi/showcase"

          puts "entrypoint:#{defined?(Sevgi::Showcase::Dark).nil?}:#{defined?(Sevgi::Showcase::Test).nil?}"

          require "sevgi/showcase/dark"
          require "sevgi/showcase/minitest"

          dark = Sevgi::Showcase.const_get(:Dark, false)
          test = Sevgi::Showcase.const_get(:Test, false)

          puts dark.apply("fill: 'black'", {"black" => "white"})

          begin
            dark.apply("fill: 'black'", {"yellow" => "purple"})
          rescue => error
            puts "dark:\#{error.class}:\#{error.message}"
          end

          begin
            test::Script.new("/no/such/showcase.sevgi")
          rescue => error
            puts "script:\#{error.class}:\#{error.message}"
          end

          success = test::Shell.run(RbConfig.ruby, "-e", "puts 'ok'")
          failure = test::Shell.run(RbConfig.ruby, "-e", "exit 3")
          puts "shell:\#{success.ok?}:\#{success.outline}:\#{failure.notok?}"
        RUBY

        out, err, status = Open3.capture3(RbConfig.ruby, *load_path, "-e", script)

        assert_predicate(status, :success?, err)
        assert_empty(err)
        assert_includes(out, "entrypoint:true:true")
        assert_includes(out, "fill: 'white'")
        assert_includes(out, "dark:Sevgi::ArgumentError:Unapplied dark mapping(s): yellow")
        assert_includes(out, "script:Sevgi::ArgumentError:No such file: /no/such/showcase.sevgi")
        assert_includes(out, "shell:true:ok:true")
      end

      private

      def load_path
        components = %w[function standard geometry graphics derender sundries toplevel showcase]
        components.flat_map { ["-I", File.expand_path("../../../#{it}/lib", __dir__)] }
      end
    end
  end
end
