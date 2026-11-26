# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # DSL helpers for SVG standard validation.
      #
      # @!method CData
      #   Returns text content used as SVG character data.
      #   @return [String, nil] joined text content or nil
      # @!method NS?(name)
      #   Reports whether a namespace is available on this element or an ancestor.
      #   @param name [Symbol, String] namespace suffix without xmlns:
      #   @return [Boolean]
      # @!method Validate
      #   Validates this subtree against SVG standard metadata when that component is available.
      #   @return [Sevgi::Graphics::Element, nil] self after validation, or nil without sevgi/standard
      #   @raise [Sevgi::ValidationError] when SVG validation fails
      module Validate
        # Returns text content used as SVG character data.
        # @return [String, nil] joined text content or nil
        def CData
          return if !contents || contents.empty?

          contents.join("\n")
        end

        # Reports whether a namespace is available on this element or an ancestor.
        # @param name [Symbol, String] namespace suffix without xmlns:
        # @return [Boolean]
        def NS?(name)
          key = :"xmlns:#{name}"
          TraverseUp { Stay(true) if it.has?(key) } || false
        end

        require "sevgi/standard"

        # Validates this subtree against the SVG standard metadata.
        # @return [Sevgi::Graphics::Element] self
        # @raise [Sevgi::ValidationError] when SVG validation fails
        def Validate
          defaults = [XML.namespace(self, :xmlns)]
          Traverse do |element, depth|
            namespace = defaults[depth + 1] = XML.default_namespace(element, defaults[depth])
            next unless (name = XML.svg_name(element, namespace))

            children = XML.svg_children(element, namespace)
            Standard.conform(name, attributes: element.attributes.keys, cdata: element.CData(), elements: children)
          end
        end

      rescue ::LoadError => e
        raise unless e.path == "sevgi/standard"

        # @overload Validate
        #   No-op validation fallback when sevgi/standard is unavailable.
        #   @return [nil]
        def Validate(...)
        end
      end
    end
  end
end
