# frozen_string_literal: true

require "sevgi"

module Sevgi
  module Binaries
    module Sevgi
      extend self

      PROGNAME = "sevgi"
      Error    = Class.new(::Sevgi::Error)

      Options = Struct.new(:require, :nomain, :vomit, :help, :version) do
        def self.parse(argv)
          new.tap do |options|
            argv.first.start_with?("-") ? option(argv, options) : break until argv.empty?
          end
        end

        class << self
          private

            def option(argv, options)
              case (arg = argv.shift)
              when "-r", "--require"   then options.require = argv.shift
              when "-m", "--nomain"    then options.nomain  = true
              when "-x", "--exception" then options.vomit   = true

              when "-h", "--help"      then options.help    = true
              when "-v", "--version"   then options.version = true
              else                          Error.("Not a valid option: #{arg}")
              end
            end
        end
      end

      private_constant :Options

      def call(argv)
        return puts(help)             if (options = Options.parse(argv = Array(argv))).help
        return puts(::Sevgi::VERSION) if options.version

        result = run(file = argv.shift, options)

        if result.error?
          raise(result.error) if options.vomit || ENV[ENVVOMIT]

          die(result.error, file)
        end
      rescue Binaries::Sevgi::Error => e
        abort(e.message)
      end

      private

        def die(e, file)
          warn(e.message)
          warn("")
          e.backtrace!.each { warn("  #{it}") }

          abort
        end

        def help
          <<~HELP
            Usage: #{PROGNAME} [options...] <SCRIPT> [ARGS...]

            See documentation for detailed help.

            Options:

            -r, --require LIB     Require Ruby LIB
            -n, --nomain          Do not modify main object
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
