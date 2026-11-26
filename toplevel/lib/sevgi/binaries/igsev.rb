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

        def libraries = self[:require]&.one? ? self[:require].first : self[:require]

        class << self
          private

          def option(argv, options)
            arg = argv.shift
            return options[FLAGS[arg]] = true if FLAGS.key?(arg)
            if %w[-r --require].include?(arg)
              return append_value(options, :require, argv, "Option requires a library: #{arg}")
            end

            return append_value(options, :omit, argv, "No attribute given for --omit") if arg == "--omit"

            Error.("Not a valid option: #{arg}")
          end

          def append_value(options, field, argv, message) = (options[field] ||= []) << (argv.shift || Error.(message))
        end
      end

      # Runs the `igsev` command-line interface.
      # @param argv [Array<String>, String, nil] command-line arguments
      # @return [nil]
      # @raise [StandardError] when `--exception` or `SEVGI_VOMIT` requests raw errors
      # @raise [SystemExit] when argv does not match `[options...] [--] [file|-]` or conversion aborts
      def call(argv)
        dispatch(Array(argv).dup)
      rescue Binaries::Igsev::Error => e
        abort("#{e.message}\n\n#{help}")
      end

      private

      def backtrace(error) = error.respond_to?(:load_backtrace) ? error.load_backtrace : (error.backtrace || [])

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
        return result.value.Out() if result.success?

        raise result.error if raw_error?(options)

        die(result.error)
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
        reader = file ? :decompile_file : :decompile
        root = ::Sevgi::Derender.public_send(reader, file || $stdin.read, omit: options.omit)
        ArgumentError.("igsev requires an SVG document root. Use igves to convert an XML fragment.") unless root.root?

        ::Sevgi.execute(root.derender, require: options.libraries)
      end
    end
  end

  private_constant :Binaries
end
