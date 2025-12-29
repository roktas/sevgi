# frozen_string_literal: true

module Sevgi
  module Test
    class Script
      attr_reader :file

      def initialize(file) = @file = ::File.expand_path(sanitize(file))

      def dir              = @dir  ||= ::File.dirname(file)

      def file!            = ::File.basename(file)

      def name             = @name ||= ::File.basename(file, ".*")

      def run(*)           = Shell.run(file, *)

      def suite            = @suite ||= ::File.basename(dir)

      def svg?             = ::File.exist?(svg)

      def svg              = @svg ||= ::File.expand_path("#{dir}/#{name}.svg")

      def svg!             = ::File.basename(svg)

      # A gross hack to avoid touching filesystem during testing.  Intercept the Save methods to display output in stdout
      # instead of saving an actual file.

      def run_passive(*)
        warn("...#{name}")
        Shell.run("sevgi", "-r", "sevgi/showcase/kludge", file, *)
      end

      private

        def sanitize(file)
          file.tap do
            ArgumentError.("No such file: #{file}")      unless ::File.exist?(file)
            ArgumentError.("Not an executable: #{file}") unless ::File.executable?(file)
          end
        end
    end
  end
end
