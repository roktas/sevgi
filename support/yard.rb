# frozen_string_literal: true

# YARD falls back cleanly when IRB is absent, but Ruby warns before that fallback.
verbose = $VERBOSE
begin
  $VERBOSE = nil
  require "yard/parser/ruby/legacy/irb/slex"

ensure
  $VERBOSE = verbose
end
