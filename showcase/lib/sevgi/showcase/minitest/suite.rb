# frozen_string_literal: true

module Sevgi
  module Test
    class Suite
      def initialize(rootdir)
        @scripts = load(rootdir)
      end

      def [](suite)
        (@cache ||= {})[suite] ||= @scripts.select { |script| script.suite == suite.to_s }
      end

      def suites
        @suites ||= @scripts.map(&:suite).uniq
      end

      NON_VALIDS = [ "gotcha" ]

      def non_valids
        NON_VALIDS.map { self[it] }.flatten
      end

      def valids
        suites.reject { NON_VALIDS.include?(it) }.map { self[it] }.flatten
      end

      private

        def load(rootdir)
          ::Dir["#{rootdir}/**/*.sevgi"].grep_v(%r{(/_|/lib/|/library/)}).map { Script.new(it) }
        end
    end
  end
end
