# frozen_string_literal: true

module Sevgi
  module Showcase
    # Minitest helpers used by the showcase component.
    # @api private
    module Test
      # Showcase script suite collection.
      # @api private
      class Suite
        # Creates a suite from a showcase root directory.
        # @param rootdir [String] showcase root directory
        # @return [void]
        def initialize(rootdir)
          @scripts = load(rootdir)
        end

        # Returns scripts belonging to a suite.
        # @param suite [String, Symbol] suite name
        # @return [Array<Sevgi::Showcase::Test::Script>]
        def [](suite)
          (@cache ||= {})[suite] ||= @scripts.select { |script| script.suite == suite.to_s }
        end

        # Returns all suite names.
        # @return [Array<String>]
        def suites
          @suites ||= @scripts.map(&:suite).uniq
        end

        # Suite names that are expected to be invalid examples.
        NON_VALIDS = ["gotcha"].freeze

        # Returns scripts expected to be invalid.
        # @return [Array<Sevgi::Showcase::Test::Script>]
        def non_valids
          NON_VALIDS.map { self[it] }.flatten
        end

        # Returns scripts expected to render successfully.
        # @return [Array<Sevgi::Showcase::Test::Script>]
        def valids
          suites.reject { NON_VALIDS.include?(it) }.map { self[it] }.flatten
        end

        alias to_a valids

        private

        def load(rootdir)
          ::Dir["#{rootdir}/**/*.sevgi"].grep_v(%r{(/_|/lib/|/library/)}).map { Script.new(it) }
        end
      end
    end
  end
end
