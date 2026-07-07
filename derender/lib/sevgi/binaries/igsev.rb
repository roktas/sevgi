# frozen_string_literal: true

require "sevgi"

module Sevgi
  module Binaries
    # Implements the `igsev` executable that derenders SVG and executes the generated Sevgi DSL.
    module Igsev
      extend self

      # Executable name used in help output.
      PROGNAME = "igsev"

      # Error raised for invalid command-line usage.
      Error = Class.new(::Sevgi::Error)

      # Parsed command-line options for the `igsev` executable.
      # @api private
      Options = Struct.new(:require, :vomit, :help, :version) do
        # Parses command-line options and removes them from the argv array.
        # @param argv [Array<String>] mutable command-line argument array
        # @return [Sevgi::Binaries::Igsev::Options] parsed options
        # @raise [Sevgi::Binaries::Igsev::Error] when an option is not recognized
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

      # Runs the `igsev` command-line interface.
      # @param argv [Array<String>, String, nil] command-line arguments
      # @return [nil]
      # @raise [LoadError] when a required Ruby library cannot be loaded
      # @raise [Sevgi::ArgumentError] when the SVG file cannot be found
      # @raise [Sevgi::Executor::Error] when `--exception` or `SEVGI_VOMIT` requests raw errors
      # @raise [Sevgi::PanicError] when generated Ruby source cannot be formatted
      # @raise [SystemExit] when command-line usage or script execution aborts
      def call(argv)
        return puts(help) if (options = Options.parse(argv = Array(argv))).help
        return puts(::Sevgi::VERSION) if options.version

        result = run(file = argv.shift, options)

        if result.error?
          raise result.error if options.vomit || ENV[ENVVOMIT]

          die(result.error, file)
        else
          result.recent.Out()
        end

      rescue Binaries::Igsev::Error => e
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

          -r, --require LIB     Require Ruby LIB
          -x, --exception       Raise exception instead of abort

          -h, --help            Show this help
          -v, --version         Display version
        HELP
      end

      def run(file, options)
        Error.("No SVG file given.") unless file

        sevgi = Derender.derender_file(file)

        ::Sevgi.execute(sevgi, require: options.require)
      end
    end
  end
end
