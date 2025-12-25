# frozen_string_literal: true

require "sevgi"

module FileUtils
  # Thin DSL wrapper to call a script without spawning a shell.
  def sevgi(file, *args, **kwargs)
    Sevgi.execute_file(F.existing!(file, [ EXTENSION ])) do |mod|
      include Sevgi

      mod.const_set(:ARGA, args).freeze
      mod.const_set(:ARGH, kwargs).freeze
    end
  end
end
