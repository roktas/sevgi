# frozen_string_literal: true

module Sevgi
  module Test
    class Script
      attr_reader :file

      def initialize(file) = @file = sanitize(file)

      def dir              = @dir  ||= ::File.dirname(file)

      def name             = @name ||= ::File.basename(file, ".*")

      def run(*)           = Shell.run(file, *)

      def suite            = @suite ||= ::File.basename(dir)

      def svg?             = ::File.exist?(svg)

      def svg              = @svg ||= "#{dir}/#{name}.svg"

      # A gross hack to avoid touching filesystem during testing.  Intercept the Save methods to display output in stdout
      # instead of saving an actual file. This hack meets the following criteria:
      #
      # - Does not make an invasive change to the library just for the sake of testing (hence the interception technique)
      # - Do not create a separate file for the interceptor (hence feeding the interceptor through /dev/stdin)

      INTERCEPTOR = <<~LIB
        class Sevgi::Graphics::Document::Base
          def Save(*, **) = Out(**)
          def Save!(...)  = Save(...)
        end
      LIB

      def run_passive(*)
        warn("  ==> #{file}")
        Shell.run("sevgi", "-l", "/dev/stdin", file, *) { puts(INTERCEPTOR) }
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
