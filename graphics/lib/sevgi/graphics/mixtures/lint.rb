# frozen_string_literal: true

module Sevgi
  module Graphics
    LintError = Class.new(Error)

    module Mixtures
      module Lint
        def Lint(...)
          IdentitiesAreUniq.(self, ...)
        end

        module IdentitiesAreUniq
          extend self

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
