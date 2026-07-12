# frozen_string_literal: true

require "sevgi"

# Extends FileUtils with Sevgi script helpers for Rake tasks.
module FileUtils
  # Thin DSL wrapper to call a script without spawning a shell.
  #
  # The script receives positional arguments through `ARGA` and keyword arguments through `ARGH`.
  #
  # @example Run a Sevgi script from a Rake task
  #   sevgi "drawings/card", "front", theme: :dark
  #
  # @param file [String] Sevgi script file, with or without `.sevgi` extension
  # @param args [Array] positional arguments exposed to the script as `ARGA`
  # @param kwargs [Hash] keyword arguments exposed to the script as `ARGH`
  # @return [Sevgi::Executor::Result] immutable execution result
  # @raise [Sevgi::ArgumentError] when the script file cannot be found
  # @see Sevgi::Executor.execute_file
  def sevgi(file, *args, **kwargs)
    Sevgi::Executor.execute_file(Sevgi::F.existing!(file, [Sevgi::EXTENSION])) do
      extend(Sevgi)

      const_set(:ARGA, args).freeze
      const_set(:ARGH, kwargs).freeze
    end
  end
end
