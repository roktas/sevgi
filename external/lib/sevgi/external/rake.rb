# frozen_string_literal: true

require "rake"
require "sevgi"

module Rake
  module DSL
    # Thin DSL wrapper to call a script without spawning a shell.
    def sevgi(file, *args)
      (save = ARGV.dup) and ARGV.replace(args) unless args.empty?

      Sevgi::Sandbox.run(file) { include Sevgi::External }
    ensure
      ARGV.replace(save) unless args.empty?
    end
  end
end
