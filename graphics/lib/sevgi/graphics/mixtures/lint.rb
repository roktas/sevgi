# frozen_string_literal: true

module Sevgi
  module Graphics
    # Raised when graphics lint checks fail.
    LintError = Class.new(Error)

    module Mixtures
      # DSL helpers for pre-render structural linting.
      module Lint
        # @overload Lint
        #   Runs graphics lint checks.
        #   @return [true]
        #   @raise [Sevgi::Graphics::LintError] when a lint check fails
        def Lint(...)
          IdentitiesAreUniq.(self, ...)
        end

        # Lint check that rejects duplicate visible ids.
        # @api private
        module IdentitiesAreUniq
          extend self

          # Checks an element subtree for duplicate ids.
          # @param element [Sevgi::Graphics::Element] root element
          # @return [true]
          # @raise [Sevgi::Graphics::LintError] when duplicate ids exist
          def call(element)
            return true unless (identifiers = element.Identifiers()).conflict?

            messages = identifiers.collision.map do |id, elements|
              "Element(s) with the same id '#{id}': #{elements.map(&:name).uniq.join(", ")}"
            end

            collisions = messages.map { |message| "\t#{message}" }.join("\n")

            LintError.("Found Id collisions:\n#{collisions}")
          end
        end

        private_constant :IdentitiesAreUniq
      end
    end
  end
end
