# frozen_string_literal: true

module Sevgi
  LintError = Class.new(Error)

  module Graphics
    module Mixtures
      module Lint
        module InstanceMethods
          def Lint(...)
            IdentitiesAreUniq.(self, ...)
          end

          module IdentitiesAreUniq
            extend self

            def call(element)
              return true unless (identifiers = element.Identifiers).conflict?

              collisions = identifiers.collision.map do |id, elements|
                "Element(s) with the same id '#{id}': #{elements.map(&:name).uniq.join(", ")}"
              end.map { "\t#{_1}" }.join("\n")

              LintError.("Found Id collisions:\n#{collisions}")
            end
          end

          private_constant :IdentitiesAreUniq
        end
      end
    end
  end
end
