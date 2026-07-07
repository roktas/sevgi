# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # DSL helpers for collecting and hiding SVG ids.
      module Identify
        # Index of element ids under a subtree.
        class Identifiers
          # @return [Sevgi::Graphics::Element] indexed root element
          attr_reader :element

          # @return [Hash<String, Sevgi::Graphics::Element>] id namespace
          attr_reader :namespace

          # @return [Hash<String, Array<Sevgi::Graphics::Element>>] duplicate id groups
          attr_reader :collision

          # Builds an id index for an element subtree.
          # @param element [Sevgi::Graphics::Element] root element
          # @return [void]
          def initialize(element)
            @element = element
            @namespace = {}
            @collision = {}

            build
          end

          # Reports whether duplicate ids were found.
          # @return [Boolean]
          def conflict?
            !@collision.empty?
          end

          # @overload [](id)
          #   Returns the element registered for an id.
          #   @param id [String] SVG id
          #   @return [Sevgi::Graphics::Element, nil]
          def [](*)
            @namespace[*]
          end

          private

          def build
            element.Traverse() do |element|
              next unless (id = element[:id])

              if @namespace.key?(id)
                (@collision[id] ||= [@namespace[id]]) << element
              else
                @namespace[id] = element
              end
            end
          end
        end

        # Moves visible id attributes to Sevgi-internal id storage.
        # @return [Sevgi::Graphics::Element] self
        def Disidentify
          Traverse do |element|
            next unless element[:id]

            element[:"#{ATTRIBUTE_INTERNAL_PREFIX}id"] = element.attributes.delete(:id)
          end
        end

        # Builds an id index for this element subtree.
        # @return [Sevgi::Graphics::Mixtures::Identify::Identifiers]
        def Identifiers = Identifiers.new(self)
      end
    end
  end
end
