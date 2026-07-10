# frozen_string_literal: true

require "sevgi"

module Sevgi
  # Command-line entrypoint implementations shipped with Sevgi.
  module Binaries
    # Implements the `sevgi` executable.
    module Sevgi
      extend self

      # Executable name used in help output.
      PROGNAME = "sevgi"

      # Error raised for invalid command-line usage.
      Error = Class.new(::Sevgi::Error)

      # Parsed command-line options for the `sevgi` executable.
      # @api private
      Options = Struct.new(:require, :nomain, :vomit, :help, :version) do
        # Parses command-line options and removes them from the argv array.
        # @param argv [Array<String>] mutable command-line argument array
        # @return [Sevgi::Binaries::Sevgi::Options] parsed options
        # @raise [Sevgi::Binaries::Sevgi::Error] when an option is not recognized
        def self.parse(argv)
          new.tap do |options|
            argv.first.start_with?("-") ? option(argv, options) : break until argv.empty?
          end
        end

        class << self
          private

          def option(argv, options)
            case (arg = argv.shift)
            when "-r", "--require"
              options.require = argv.shift
            when "-n", "--nomain"
              options.nomain = true
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

      # Runs the `sevgi` command-line interface.
      # @param argv [Array<String>, String, nil] command-line arguments
      # @return [nil]
      # @raise [Sevgi::Executor::Error] when `--exception` or `SEVGI_VOMIT` requests raw executor errors
      # @raise [SystemExit] when command-line usage or script execution aborts
      def call(argv)
        return puts(help) if (options = Options.parse(argv = Array(argv))).help
        return puts(::Sevgi::VERSION) if options.version

        result = run(file = argv.shift, options)

        if result.error?
          raise result.error if options.vomit || ENV[ENVVOMIT]

          die(result.error, file)
        end

      rescue Binaries::Sevgi::Error => e
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
          Usage: #{PROGNAME} [options...] <Sevgi file>

          See documentation for detailed help.

          Options:

          -n, --nomain          Do not modify main object
          -r, --require LIB     Require Ruby LIB
          -x, --exception       Raise exception instead of abort

          -h, --help            Show this help
          -v, --version         Display version
        HELP
      end

      def run(file, options)
        Error.("No sevgi file given.") unless file

        ::Sevgi.execute_file(file, require: options.require, receiver: options.nomain ? nil : TOPLEVEL_BINDING.receiver)
      end
    end
  end
end
