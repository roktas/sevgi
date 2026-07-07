# frozen_string_literal: true

require "sevgi"

module Sevgi
  module Binaries
    # Implements the `igves` executable that converts SVG files into Sevgi DSL source.
    module Igves
      extend self

      # Executable name used in help output.
      PROGNAME = "igves"

      # Error raised for invalid command-line usage.
      Error = Class.new(::Sevgi::Error)

      # Parsed command-line options for the `igves` executable.
      # @api private
      Options = Struct.new(:vomit, :help, :version) do
        # Parses command-line options and removes them from the argv array.
        # @param argv [Array<String>] mutable command-line argument array
        # @return [Sevgi::Binaries::Igves::Options] parsed options
        # @raise [Sevgi::Binaries::Igves::Error] when an option is not recognized
        def self.parse(argv)
          new.tap do |options|
            argv.first.start_with?("-") ? option(argv, options) : break until argv.empty?
          end
        end

        class << self
          private

          def option(argv, options)
            case (arg = argv.shift)
            when "-x", "--exception"
              options.vomit = true
            when "-h", "--help"
              options.help = true
            when "-v", "--version"
              options.version = true
            else
              Error.("Not a valid option: #{arg}")
            end
          end
        end
      end

      private_constant :Options

      # Runs the `igves` command-line interface.
      # @param argv [Array<String>, String, nil] command-line arguments
      # @return [nil]
      # @raise [Sevgi::ArgumentError] when the SVG file cannot be found
      # @raise [Sevgi::PanicError] when generated Ruby source cannot be formatted
      # @raise [SystemExit] when command-line usage aborts
      def call(argv)
        return puts(help) if (options = Options.parse(argv = Array(argv))).help
        return puts(::Sevgi::VERSION) if options.version

        puts(run(argv.shift, options))
      rescue Binaries::Igves::Error => e
        abort(e.message)
      end

      private

      def die(error, _file)
        warn(error.message)
        warn("")
        error.backtrace!.each { warn("  #{it}") }

        exit(1)
      end

      def help
        <<~HELP
          Usage: #{PROGNAME} [options...] <SVG file>

          See documentation for detailed help.

          Options:

          -x, --exception       Raise exception instead of abort
          -h, --help            Show this help
          -v, --version         Display version
        HELP
      end

      def run(file, _options)
        Error.("No SVG file given.") unless file

        Derender.derender_file(file)
      end
    end
  end
end
