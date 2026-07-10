# frozen_string_literal: true

require "open3"
require "rbconfig"

require_relative "../test_helper"

module Sevgi
  module Showcase
    class StandaloneTest < Minitest::Test
      def test_showcase_entrypoint_loads_and_reports_sevgi_errors_standalone
        script = <<~RUBY
          require "sevgi/showcase"

          puts Sevgi::Showcase::Dark.apply("fill: 'black'", {"black" => "white"})

          begin
            Sevgi::Showcase::Dark.apply("fill: 'black'", {"yellow" => "purple"})
          rescue => error
            puts "dark:\#{error.class}:\#{error.message}"
          end

          begin
            Sevgi::Test::Script.new("/no/such/showcase.sevgi")
          rescue => error
            puts "script:\#{error.class}:\#{error.message}"
          end

          success = Sevgi::Test::Shell.run(RbConfig.ruby, "-e", "puts 'ok'")
          failure = Sevgi::Test::Shell.run(RbConfig.ruby, "-e", "exit 3")
          puts "shell:\#{success.ok?}:\#{success.outline}:\#{failure.notok?}"
        RUBY

        out, err, status = Open3.capture3(RbConfig.ruby, *load_path, "-e", script)

        assert_predicate(status, :success?, err)
        assert_empty(err)
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
