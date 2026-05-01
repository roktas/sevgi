# frozen_string_literal: true

require "sevgi"

module Sevgi
  module Binaries
    module Igves
      extend self

      PROGNAME = "igves"
      Error    = Class.new(::Sevgi::Error)

      Options = Struct.new(:vomit, :help, :version) do
        def self.parse(argv)
          new.tap do |options|
            argv.first.start_with?("-") ? option(argv, options) : break until argv.empty?
          end
        end

        class << self
          private

            def option(argv, options)
              case (arg = argv.shift)
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

        puts run(file = argv.shift, options)
      rescue Binaries::Igves::Error => error
        abort(error.message)
      end

      private

        def die(error, file)
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

        def run(file, options)
          Error.("No SVG file given.") unless file

          Derender.derender_file(file)
        end
    end
  end
end
