# frozen_string_literal: true

require_relative "../test_helper"

require "sevgi/binaries/rake"
require "tmpdir"
require "rake"

module Sevgi
  module Binaries
    class RakeTest < Minitest::Test
      def test_sevgi_failure_stops_dependent_task
        Dir.mktmpdir do |dir|
          file = File.join(dir, "drawing.sevgi")
          File.write(file, "raise \"generation failed\"")
          application = ::Rake::Application.new
          application.define_task(::Rake::Task, :drawing) { Object.new.extend(::FileUtils).sevgi(file) }
          ran = false
          task = application.define_task(::Rake::Task, publish: :drawing) { ran = true }

          error = assert_raises(Executor::Error) { task.invoke }
          assert_instance_of(::RuntimeError, error.cause)
          assert_equal("generation failed", error.message)
          refute(ran)
        end
      end

      def test_sevgi_executes_script_with_arguments
        Dir.mktmpdir do |dir|
          file = File.join(dir, "drawing.sevgi")
          File.write(
            file,
            <<~RUBY
              raise "bad ARGA" unless ARGA == ["left"]
              raise "bad ARGH" unless ARGH == {name: "grid"}

              SVG do
                text ARGH.fetch(:name)
              end
            RUBY
          )

          result = Object.new.extend(::FileUtils).sevgi(File.join(dir, "drawing"), "left", name: "grid")

          refute(result.error?, result.error&.message)
          assert_includes(result.value.(), ">grid<")
        end
      end
    end
  end
end
