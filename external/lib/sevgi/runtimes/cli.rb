# frozen_string_literal: true

require "sevgi"

module Sevgi
  module CLI
    extend self

    Error = Class.new(Sevgi::Error)

    Options = Struct.new(:preload, :require, :vomit, :help, :version) do
      # codebeat:disable[ABC,BLOCK_NESTING,LOC]
      def self.parse(argv)
        new.tap do |options|
          argv.first.start_with?("-") ? option(argv, options) : break until argv.empty?

          Error.("No preload file found: #{options.preload}") if options.preload && !::File.exist?(options.preload)
        end
      end

      class << self
        private

          def option(argv, options)
            case (arg = argv.shift)
            when "-l", "--preload"   then options.preload = argv.shift
            when "-r", "--require"   then options.require = argv.shift
            when "-x", "--exception" then options.vomit   = true
            when "-h", "--help"      then options.help    = true
            when "-v", "--version"   then options.version = true
            else                          Error.("Not a valid option: #{arg}")
            end
          end
      end
      # codebeat:enable[ABC,BLOCK_NESTING,LOC]
    end

    private_constant :Options

    def call(argv)
      argv = Array(argv) # FIXME

      return puts(help)           if (options = Options.parse(argv)).help
      return puts(Sevgi::VERSION) if options.version

      run(file = argv.shift, options)
    rescue CLI::Error => e
      abort(e.message)
    rescue Sandbox::Error => e
      raise(e) if options.vomit || ENV[ENVVOMIT]

      die(e, file)
    end

    private

      def die(e, file)
        warn(e.message)
        warn("")
        e.backtrace!.each { warn("  #{it}") }

        warn("")
        abort(postmortem(file))
      end

      # codebeat:disable[ABC,LOC]
      def help
        <<~HELP
          Usage: #{PROGNAME} [options...] <SCRIPT> [ARGS...]

          See documentation for detailed help.

          Options:

          -l, --preload FILE    Preload Ruby FILE
          -r, --require LIB     Require Ruby LIB
          -x, --exception       Raise exception instead of abort
          -h, --help            Show this help
          -v, --version         Display version
        HELP
      end

      def postmortem(file)
        <<~POSTMORTEM
          For more details, run the script again:

          - By using the -x switch: '#{PROGNAME} -x #{file}'
          - By setting the #{ENVVOMIT} environment variable: '#{ENVVOMIT}=t #{file}'

          If you think this is a bug, you can report it by creating an issue.
        POSTMORTEM
      end

      def run(file, options)
        Error.("No script file given.") unless file

        Sevgi::Sandbox.run(file, require: options.require, preload: options.preload)
      end
  end
end
