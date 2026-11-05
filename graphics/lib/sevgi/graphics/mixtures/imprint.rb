# frozen_string_literal: true

require "json"

module Sevgi
  module Graphics
    module Mixtures
      # Document-local page metadata and editable paint declarations for PDF export.
      module Imprint
        # Immutable authoring declaration for PDF page metadata and editable paint properties.
        # Source selectors stay here; the producer resolves them to PDF targets and baselines.
        # @api private
        class Declaration
          # Captures a declaration without changing the SVG or loading a PDF backend.
          # @param definition [Hash] targets, parameters, optional page, groups and profileSets
          # @yield evaluates authoring operations in a private builder
          # @yieldreturn [Object] ignored block result
          # @return [void]
          # @raise [Sevgi::ArgumentError] when the declaration is not finite, acyclic JSON data
          def initialize(definition = {}, &block)
            ArgumentError.("Imprint declaration must be a Hash") unless definition.is_a?(::Hash)
            ArgumentError.("Imprint accepts a declaration or a block") if block && !definition.empty?

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
            unknown = @definition.keys - %w[targets parameters page groups profileSets]
            ArgumentError.("Unknown Imprint field: #{unknown.first}") unless unknown.empty?
            return if %w[targets parameters].all? { @definition[it].is_a?(::Hash) }
            ArgumentError.("Imprint requires targets and parameters")
          end

          # Authoring operations kept outside the SVG method namespace.
          # @api private
          class Builder
            def initialize
              @definition = {targets: {}, parameters: {}, groups: [], profileSets: []}
            end

            def call(&block)
              instance_exec(&block)
              @definition.delete(:groups) if @definition[:groups].empty?
              @definition.delete(:profileSets) if @definition[:profileSets].empty?
              @definition
            end

            def Page(name: Undefined, tags: Undefined)
              ArgumentError.("Page is already declared") if @definition.key?(:page)
              @definition[:page] = {name:, tags:}.reject { |_, value| value.equal?(Undefined) }
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
                ArgumentError.("Imprint id must be nonempty text")
              end
              id = id.to_s
              ArgumentError.("Duplicate Imprint id: #{id}") if @definition[field].key?(id)
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
              ArgumentError.("Invalid Imprint JSON: #{e.message}")
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

        # Reads or replaces this document's Imprint declaration.
        # A declaration changes export metadata, not rendered SVG appearance.
        # Ordinary document copies safely share the immutable declaration.
        # @param definition [Hash, Sevgi::Undefined] declaration, or omitted for a read
        # @yield defines Page, Target, Param, Group, and Profiles records
        # @yieldreturn [Object] ignored block result
        # @return [Hash, nil, Sevgi::Graphics::Element] frozen JSON declaration on read, self on assignment
        # @raise [Sevgi::ArgumentError] when called outside a document root or with an invalid declaration
        # @example Declare a named page with an editable outline
        #   drawing.Imprint do
        #     Page name: "Practice", tags: ["guide"]
        #     Target "ink", selectors: ["#outline"]
        #     Param "display", targets: ["ink"], property: "display",
        #       schema: {type: "string", enum: %w[inline none]}
        #     Param "opacity", targets: ["ink"], property: "stroke-opacity",
        #       schema: {type: "number", minimum: 0, maximum: 1}
        #   end
        def Imprint(definition = Undefined, &block)
          ArgumentError.("Imprint belongs to a document root") unless Root?()
          return @imprint&.to_h if definition.equal?(Undefined) && !block
          definition = {} if definition.equal?(Undefined)
          @imprint = Declaration.new(definition, &block)
          self
        end
      end
    end
  end
end
