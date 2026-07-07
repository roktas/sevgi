# frozen_string_literal: true

module Sevgi
  module Function
    # Small terminal status helpers used by build and release tasks.
    module UI
      # Reports an in-progress status message.
      # @param message [Object] status message
      # @return [nil]
      def do(message) = warn("#{cyan("···")} #{bold(message)}")

      # Reports an optional neutral status message unless SILENT is set.
      # @param message [Object] status message
      # @return [nil]
      def mayok(message) = (warn("  #{dim("·")} #{dim(message)}") unless ENV["SILENT"])

      # Reports a failure status message.
      # @param message [Object] status message
      # @return [nil]
      def notok(message) = warn("  #{red("✗")} #{bold(message)}")

      # Reports a success status message.
      # @param message [Object] status message
      # @return [nil]
      def ok(message) = warn("  #{cyan("✓")} #{bold(message)}")

      # Reports a status message according to the yielded value.
      # @param message [Object] status message
      # @yield computes the status value
      # @yieldreturn [Object]
      # @return [Object] yielded value
      def ui(message) = yield.tap { it ? ok(message) : notok(message) }
    end

    extend UI
  end
end
