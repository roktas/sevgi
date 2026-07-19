# frozen_string_literal: true

require "lint_roller"

require_relative "../../sevgi/appendix"

# RuboCop integration shipped with Sevgi Appendix.
module RuboCop
  # Sevgi DSL integration for RuboCop.
  module Sevgi
    # Connects Sevgi's `.sevgi` rules to RuboCop's plugin system.
    class Plugin < LintRoller::Plugin
      # Describes this plugin to lint_roller.
      # @return [LintRoller::About] plugin metadata
      def about
        LintRoller::About.new(
          name: "sevgi-appendix",
          version: ::Sevgi::Appendix::VERSION,
          homepage: "https://sevgi.roktas.dev",
          description: "RuboCop rules for the Sevgi SVG DSL"
        )
      end

      # Reports whether this plugin supports the requested lint engine.
      # @param context [LintRoller::Context] lint engine context
      # @return [Boolean] true for RuboCop
      def supported?(context) = context.engine == :rubocop

      # Returns the RuboCop configuration bundled with this gem.
      # @param _context [LintRoller::Context] lint engine context
      # @return [LintRoller::Rules] path-backed RuboCop rules
      def rules(_context)
        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: File.expand_path("../../../rubocop/config/default.yml", __dir__)
        )
      end
    end
  end
end
