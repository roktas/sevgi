#!/usr/bin/env ruby
# frozen_string_literal: true

require "sevgi"

module Sevgi
  module Binaries
    module Igves
      extend self

      Error = Class.new(::Sevgi::Error)

      Options = Struct.new(:preload, :require, :vomit, :help, :version) do
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
      end

      private_constant :Options

      def call(argv)
        return puts(help)           if (options = Options.parse(argv = Array(argv))).help
        return puts(::Sevgi::VERSION) if options.version

        puts Derender.derender_file(file = argv.shift)
      rescue Binaries::Igves::Error => e
        abort(e.message)
      rescue ::Sevgi::Sandbox::Error => e
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
            If you think this is a bug, you can report it by creating an issue. For details, run the script again:

              - By using the -x switch: '#{PROGNAME} -x #{file}'
              - By setting the #{ENVVOMIT} environment variable: '#{ENVVOMIT}=t #{file}'
          POSTMORTEM
        end
    end
  end
end
