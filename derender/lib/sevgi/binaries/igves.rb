# frozen_string_literal: true

require "sevgi"

module Sevgi
  # Command-line entrypoint implementations shipped with Sevgi.
  # @api private
  module Binaries
    # Implements the `igves` executable that converts SVG files into Sevgi DSL source.
    # @api private
    module Igves
      extend self

      # Executable name used in help output.
      PROGNAME = "igves"

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

      # Parsed command-line options for the `igves` executable.
      # @api private
      Options = Struct.new(:vomit, :help, :version, :omit) do
        # Parses command-line options and removes them from the argv array.
        # @param argv [Array<String>] mutable command-line argument array
        # @return [Sevgi::Binaries::Igves::Options] parsed options
        # @raise [Sevgi::Binaries::Igves::Error] when an option is not recognized
        def self.parse(argv)
          new.tap do |options|
            until argv.empty?
              break unless argv.first.start_with?("-")
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
            return (options.omit ||= []) << (argv.shift || Error.("No attribute given for --omit")) if arg == "--omit"

            Error.("Not a valid option: #{arg}")
          end
        end
      end

      private_constant :Options

      # Runs the `igves` command-line interface.
      # @param argv [Array<String>, String, nil] command-line arguments
      # @return [nil]
      # @raise [Sevgi::ArgumentError] when the SVG file cannot be found
      # @raise [Sevgi::PanicError] when generated Ruby source cannot be formatted
      # @raise [StandardError] when `--exception` or `SEVGI_VOMIT` requests raw errors
      # @raise [SystemExit] when argv does not match `[options...] [--] <file>` or command-line usage aborts
      def call(argv)
        dispatch(Array(argv))
      rescue Binaries::Igves::Error => e
        abort("#{e.message}\n\n#{help}")
      end

      private

      def dispatch(argv)
        options = Options.parse(argv)
        return puts(help) if options.help
        return puts(::Sevgi::VERSION) if options.version

        print_file(operand(argv), options)
      rescue Binaries::Igves::Error
        raise
      rescue ::StandardError => e
        raise if raw_error?(options)

        die(e, nil)
      end

      def die(error, _file)
        warn(error.message)
        warn("")
        backtrace(error).each { warn("  #{it}") }

        exit(1)
      end

      def backtrace(error)
        return error.backtrace! if error.respond_to?(:backtrace!)

        error.backtrace || []
      end

      def help
        <<~HELP
          Usage: #{PROGNAME} [options...] [--] <SVG file>

          See documentation for detailed help.

          Options:

          -x, --exception       Raise exception instead of abort
          --omit ATTRIBUTE      Omit an attribute (repeatable)
          --                    Stop option parsing
          -h, --help            Show this help
          -v, --version         Display version
        HELP
      end

      def operand(argv)
        file = argv.shift || Error.("No SVG file given.")
        Error.("Unexpected argument: #{argv.first}") unless argv.empty?

        file
      end

      def run(file, options)
        Derender.derender_file(file, omit: options.omit)
      end

      def print_file(file, options)
        puts(run(file, options))
      rescue Binaries::Igves::Error
        raise
      rescue ::StandardError => e
        raise if raw_error?(options)

        die(e, file)
      end

      def raw_error?(options)
        options&.vomit || ENV.fetch(ENVVOMIT, nil)
      end
    end
  end

  private_constant :Binaries
end
