# frozen_string_literal: true

require "sevgi"
require "sevgi/skill"

module Sevgi
  # Command-line entrypoint implementations shipped with Sevgi.
  # @api private
  module Binaries
    # Implements the `sevgi` executable.
    # @api private
    module Sevgi
      extend self

      # Executable name used in help output.
      PROGNAME = "sevgi"

      # Logical source name used for standard input.
      STDIN_NAME = "output.sevgi"

      # Error raised for invalid command-line usage.
      Error = Class.new(::Sevgi::Error)

      FLAGS = {
        "-x" => :vomit,
        "--exception" => :vomit,
        "-h" => :help,
        "--help" => :help,
        "--skill" => :skill,
        "-v" => :version,
        "--version" => :version
      }.freeze

      # Parsed command-line options for the `sevgi` executable.
      # @api private
      Options = Struct.new(:require, :vomit, :help, :skill, :version, :as) do
        # Parses command-line options and removes them from the argv array.
        # @param argv [Array<String>] mutable command-line argument array
        # @return [Sevgi::Binaries::Sevgi::Options] parsed options
        # @raise [Sevgi::Binaries::Sevgi::Error] when an option is not recognized or a required value is missing
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
            if (flag = FLAGS[arg])
              options[flag] = true
            elsif ["-r", "--require"].include?(arg)
              options.require = argv.shift || Error.("Option requires a library: #{arg}")
            elsif arg == "--as"
              options.as = argv.shift
              Error.("Option requires a name: --as") if options.as.nil? || options.as.empty?
            else
              Error.("Not a valid option: #{arg}")
            end
          end
        end
      end

      private_constant :FLAGS, :Options, :STDIN_NAME

      # Runs the `sevgi` command-line interface.
      # @param argv [Array<String>, String, nil] command-line arguments
      # @return [nil]
      # @raise [Sevgi::Executor::Error] when `--exception` or `SEVGI_VOMIT` requests raw executor errors
      # @raise [SystemExit] when argv does not match `[options...] [--] [file|-]` or script execution aborts
      def call(argv)
        return puts(help) if (options = Options.parse(argv = Array(argv))).help
        return puts(Skill.path) if options.skill
        return puts(::Sevgi::VERSION) if options.version

        file = operand(argv)
        handle(run(file, options), file, options)

      rescue Skill::Error => e
        abort(e.message)
      rescue Binaries::Sevgi::Error => e
        abort("#{e.message}\n\n#{help}")
      end

      private

      def die(error, _file)
        warn(error.message, "", *error.load_backtrace.map { "  #{it}" })
        exit(1)
      end

      def handle(result, file, options)
        return unless result&.error?

        raise result.error if options.vomit || ENV[ENVVOMIT]

        die(result.error, file)
      end

      def help
        <<~HELP
          Usage: #{PROGNAME} [options...] [--] [Sevgi file|-]

          See documentation for detailed help.

          Options:

              --as NAME         Evaluate input as NAME for implicit output names
          -r, --require LIB     Require Ruby LIB
              --skill           Display the packaged agent skill path
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

      def execute_file(file, options)
        name = source_name(options.as) if options.as
        ::Sevgi.execute_file(file, as: name, require: options.require, main: false)
      end

      def run(file, options)
        return execute_file(file, options) if file

        ::Sevgi.execute($stdin.read, file: source_name(options.as), require: options.require, main: false)
      end

      def source_name(name)
        return STDIN_NAME unless name

        Error.("Option requires a name, not a path: --as") unless ::File.basename(name) == name
        F.subext(".sevgi", name)
      end
    end
  end

  private_constant :Binaries
end
