# frozen_string_literal: true

require "sevgi"

module Sevgi
  # Command-line entrypoint implementations shipped with Sevgi.
  # @api private
  module Binaries
    # Implements the `igsev` executable that round-trips SVG files through Sevgi.
    # @api private
    module Igsev
      extend self

      # Executable name used in help output.
      PROGNAME = "igsev"

      # Error raised for invalid command-line usage.
      Error = Class.new(::Sevgi::Error)

      FLAGS = {
        "--exception" => :vomit,
        "--help" => :help,
        "--version" => :version,
        "-h" => :help,
        "-v" => :version,
        "-x" => :vomit
      }.freeze
      private_constant :FLAGS

      # Parsed command-line options for the `igsev` executable.
      # @api private
      Options = Struct.new(:require, :vomit, :help, :version, :omit) do
        # Parses command-line options and removes them from the argv array.
        # @param argv [Array<String>] mutable command-line argument array
        # @return [Sevgi::Binaries::Igsev::Options] parsed options
        # @raise [Sevgi::Binaries::Igsev::Error] when an option is not recognized or a required value is missing
        def self.parse(argv)
          new.tap do |options|
            until argv.empty? || argv.first == "-" || !argv.first.start_with?("-")
              if argv.first == "--"
                argv.shift
                break
              end

              option(argv, options)
            end
          end
        end

        class << self
          private

          def option(argv, options)
            arg = argv.shift
            return options[FLAGS[arg]] = true if FLAGS.key?(arg)
            if ["-r", "--require"].include?(arg)
              return options.require = argv.shift || Error.("Option requires a library: #{arg}")
            end

            return (options.omit ||= []) << (argv.shift || Error.("No attribute given for --omit")) if arg == "--omit"

            Error.("Not a valid option: #{arg}")
          end
        end
      end

      private_constant :Options

      # Runs the `igsev` command-line interface.
      # @param argv [Array<String>, String, nil] command-line arguments
      # @return [nil]
      # @raise [StandardError] when `--exception` or `SEVGI_VOMIT` requests raw errors
      # @raise [SystemExit] when argv does not match `[options...] [--] [file|-]` or conversion aborts
      def call(argv)
        dispatch(Array(argv))
      rescue Binaries::Igsev::Error => e
        abort("#{e.message}\n\n#{help}")
      end

      private

      def backtrace(error)
        return error.load_backtrace if error.respond_to?(:load_backtrace)

        error.backtrace || []
      end

      def die(error)
        warn(error.message)
        warn("")
        backtrace(error).each { warn("  #{it}") }

        exit(1)
      end

      def dispatch(argv)
        options = Options.parse(argv)
        return puts(help) if options.help
        return puts(::Sevgi::VERSION) if options.version

        emit(operand(argv), options)
      rescue Binaries::Igsev::Error
        raise
      rescue ::StandardError => e
        raise if raw_error?(options)

        die(e)
      end

      def emit(file, options)
        result = run(file, options)
        unless result.success?
          raise result.error if raw_error?(options)

          die(result.error)
        end

        result.value.Out()
      end

      def help
        <<~HELP
          Usage: #{PROGNAME} [options...] [--] [SVG file|-]

          See documentation for detailed help.

          Options:

              --omit ATTRIBUTE  Omit an attribute (repeatable)
          -r, --require LIB     Require Ruby LIB while evaluating generated source
          -x, --exception       Raise exception instead of abort
              --                Stop option parsing

          -h, --help            Show this help
          -v, --version         Display version
        HELP
      end

      def operand(argv)
        file = argv.shift
        Error.("Unexpected argument: #{argv.first}") unless argv.empty?

        file unless file == "-"
      end

      def raw_error?(options) = options&.vomit || ENV.fetch(ENVVOMIT, nil)

      def run(file, options)
        source = if file
          ::Sevgi::Derender.derender_file(file, omit: options.omit)
        else
          ::Sevgi::Derender.derender($stdin.read, omit: options.omit)
        end

        ::Sevgi.execute(source, require: options.require)
      end
    end
  end

  private_constant :Binaries
end
