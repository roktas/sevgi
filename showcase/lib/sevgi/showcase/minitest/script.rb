# frozen_string_literal: true

module Sevgi
  module Showcase
    # Minitest helpers used by the showcase component.
    # @api private
    module Test
      # Executable showcase script descriptor.
      # @api private
      class Script
        # @return [String] absolute script path
        attr_reader :file

        # Creates a script descriptor.
        # @param file [String] executable .sevgi file
        # @return [void]
        # @raise [Sevgi::ArgumentError] when the file is missing or not executable
        def initialize(file) = @file = ::File.expand_path(sanitize(file))

        # Returns the script directory.
        # @return [String]
        def dir = @dir ||= ::File.dirname(file)

        # Returns the script basename.
        # @return [String]
        def file! = ::File.basename(file)

        # Returns the script name without extension.
        # @return [String]
        def name = @name ||= ::File.basename(file, ".*")

        # @overload run(*args)
        #   Runs the script directly.
        #   @param args [Array<String>] extra command arguments
        #   @return [Sevgi::Showcase::Test::Shell::Result]
        def run(*) = Shell.run(file, *)

        # Returns the script suite name.
        # @return [String]
        def suite = @suite ||= ::File.basename(dir)

        # Reports whether the expected SVG output exists.
        # @return [Boolean]
        def svg? = ::File.exist?(svg)

        # Returns the expected SVG output path.
        # @return [String]
        def svg = @svg ||= ::File.expand_path("#{dir}/#{name}.svg")

        # Returns the expected SVG output basename.
        # @return [String]
        def svg! = ::File.basename(svg)

        # Returns the optional YAML metadata path.
        # @return [String]
        def yml = @yml ||= ::File.expand_path("#{dir}/#{name}.yml")

        # Returns the optional YAML metadata basename.
        # @return [String]
        def yml! = ::File.basename(yml)

        # @overload run_passive(*args)
        #   Runs the script without writing Save output to files.
        #   @param args [Array<String>] extra command arguments
        #   @return [Sevgi::Showcase::Test::Shell::Result]
        def run_passive(*)
          warn("...#{name}")
          Shell.run("sevgi", "-r", "sevgi/showcase/passive", file, *)
        end

        private

        def sanitize(file)
          file.tap do
            ArgumentError.("No such file: #{file}") unless ::File.exist?(file)
            ArgumentError.("Not an executable: #{file}") unless ::File.executable?(file)
          end
        end
      end
    end
  end
end
