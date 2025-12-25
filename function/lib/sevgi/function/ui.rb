# frozen_string_literal: true

module Sevgi
  module Function
    module UI
      def do(message)    = warn "#{cyan("···")} #{bold(message)}"
      def mayok(message) = (warn "  #{dim("·")} #{dim(message)}" unless ENV["SILENT"])
      def notok(message) = warn "  #{red("✗")} #{bold(message)}"
      def ok(message)    = warn "  #{cyan("✓")} #{bold(message)}"
      def ui(message)    = yield.tap { it ? ok(message) : notok(message) }
    end

    extend UI
  end
end
