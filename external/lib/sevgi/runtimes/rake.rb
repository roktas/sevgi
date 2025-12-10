# frozen_string_literal: true

require "sevgi"

module FileUtils
  # Thin DSL wrapper to call a script without spawning a shell.
  def sevgi(...) = Sevgi.exec(...)
end
