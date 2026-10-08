# frozen_string_literal: true

require "json"

module Sevgi
  module Graphics
    module Mixtures
      module Style
        # Immutable authoring declaration for editable PDF paint properties.
        # Source selectors stay here; the producer resolves them to PDF targets and baselines.
        # @api private
        class Declaration
          # Captures a declaration without changing the SVG or loading a PDF backend.
          # @param definition [Hash] targets, parameters, optional groups and profileSets
          # @yield evaluates authoring operations in a private builder
          # @yieldreturn [Object] ignored block result
          # @return [void]
          # @raise [Sevgi::ArgumentError] when the declaration is not finite, acyclic JSON data
          def initialize(definition = {}, &block)
            ArgumentError.("Style declaration must be a Hash") unless definition.is_a?(::Hash)
            ArgumentError.("Style accepts a declaration or a block") if block && !definition.empty?

            definition = Builder.new.call(&block) if block
            @definition = Snapshot.capture(definition)
            validate
            freeze
          end

          # Returns the owned, deeply frozen declaration with JSON String keys.
          # @return [Hash{String => Object}] producer authoring declaration
          def to_h = @definition

          private

          def validate
            unknown = @definition.keys - %w[targets parameters groups profileSets]
            ArgumentError.("Unknown Style field: #{unknown.first}") unless unknown.empty?
            return if %w[targets parameters].all? { @definition[it].is_a?(::Hash) }
            ArgumentError.("Style requires targets and parameters")
          end

          # Authoring operations kept outside the SVG method namespace.
          # @api private
          class Builder
            def initialize
              @definition = {targets: {}, parameters: {}, groups: [], profileSets: []}
            end

            def call(&block)
              instance_exec(&block)
              @definition
            end

            def Target(id, selectors:, fill: false, display: Undefined)
              record = {selectors:, fill:}
              record[:display] = display unless display.equal?(Undefined)
              add(:targets, id, record)
            end

            def Param(id, targets:, property:, schema:, value: Undefined)
              record = {schema:, binding: {targets:, property:}}
              record[:value] = value unless value.equal?(Undefined)
              add(:parameters, id, record)
            end

            def Group(title, parameters:, description: nil)
              record = {title:, parameters:}
              record[:description] = description unless description.nil?
              @definition[:groups] << record
            end

            def Profiles(id, name:, parameters:, profiles:, description: nil)
              record = {id:, name:, parameters:, profiles:}
              record[:description] = description unless description.nil?
              @definition[:profileSets] << record
            end

            private

            def add(field, id, value)
              unless (id.is_a?(::String) || id.is_a?(::Symbol)) && !id.to_s.empty?
                ArgumentError.("Style id must be nonempty text")
              end
              id = id.to_s
              ArgumentError.("Duplicate Style id: #{id}") if @definition[field].key?(id)
              @definition[field][id] = value
            end
          end

          # JSON ownership rules differ from XML profile metadata.
          # @api private
          module Snapshot
            def self.capture(value)
              json = JSON.generate(value, strict: true, max_nesting: 32)
              freeze_tree(JSON.parse(json, max_nesting: 32))
            rescue JSON::JSONError => e
              ArgumentError.("Invalid Style JSON: #{e.message}")
            end

            def self.freeze_tree(value)
              case value
              when ::Hash then value.each_value { freeze_tree(it) }
              when ::Array then value.each { freeze_tree(it) }
              end
              value.freeze
            end

            private_class_method :freeze_tree
          end

          private_constant :Builder, :Snapshot
        end
        private_constant :Declaration
      end
    end
  end
end
