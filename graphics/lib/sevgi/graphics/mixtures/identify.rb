# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # DSL helpers for collecting and hiding SVG ids.
      module Identify
        # Immutable snapshot of every rendered element id under a subtree. Keys are the serialized id values, including
        # `"false"` and the empty String. Keys and containers are owned by the index; values retain references to the
        # elements present when the snapshot is built. Later tree changes require a new index.
        class Identifiers
          # @return [Sevgi::Graphics::Element] indexed root element
          attr_reader :element

          # @return [Hash<String, Sevgi::Graphics::Element>] frozen namespace keyed by serialized rendered ids
          attr_reader :namespace

          # @return [Hash<String, Array<Sevgi::Graphics::Element>>] frozen duplicate groups keyed by serialized ids
          attr_reader :collision

          # Builds an id index for an element subtree.
          # @param element [Sevgi::Graphics::Element] root element
          # @return [void]
          def initialize(element)
            @element = element
            @namespace = {}
            @collision = {}

            build
            @namespace.freeze
            @collision.each_value(&:freeze)
            @collision.freeze
            freeze
          end

          # Reports whether duplicate ids were found.
          # @return [Boolean]
          def conflict?
            !@collision.empty?
          end

          # Returns the first element registered for an id in the snapshot.
          # Duplicate entries are available through {#collision}.
          # @param id [String] serialized rendered SVG id
          # @return [Sevgi::Graphics::Element, nil]
          def [](id) = @namespace[id]

          private

          def build
            element.Traverse() do |element|
              next unless element.attributes.has?(:id)

              value = element[:id]
              id = Attribute.xml_text(value).dup.freeze

              if @namespace.key?(id)
                (@collision[id] ||= [@namespace[id]]) << element
              else
                @namespace[id] = element
              end
            end
          end
        end

        # Moves visible id attributes to non-rendering `-id` metadata throughout the subtree.
        # A pre-existing `-id` takes precedence over the visible id.
        # @return [Sevgi::Graphics::Element] self
        # @example Hide ids while retaining their source identity
        #   document = SVG { rect(id: "source-id") }
        #   document.Disidentify
        #   document.children.first[:"-id"] # => "source-id"
        def Disidentify
          Traverse do |element|
            next unless element.attributes.has?(:id)

            id = element.attributes.delete(:id)
            metadata = :"#{Attributes::META_PREFIX}id"
            element[metadata] = id unless element.attributes.has?(metadata)
          end
        end

        # Builds an immutable id index snapshot for the current element subtree.
        # Rebuild the index to observe later id or tree changes.
        # @return [Sevgi::Graphics::Mixtures::Identify::Identifiers] new snapshot retaining indexed element references
        def Identifiers = Identifiers.new(self)
      end
    end
  end
end
