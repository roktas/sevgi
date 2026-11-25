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

        # Resolves SVG names in the active XML namespace scope.
        # @api private
        class NamespaceScope
          SVG_URI = "http://www.w3.org/2000/svg"

          def initialize(root)
            @defaults = [binding(root.parent, :xmlns)]
          end

          def enter(element, depth)
            namespace = @defaults[depth + 1] = default(element, @defaults[depth])
            svg_name(element, namespace)
          end

          def children(element, depth)
            namespace = @defaults[depth + 1]
            element.children.filter_map { svg_name(it, default(it, namespace)) }
          end

          private

          def binding(element, key)
            element&.TraverseUp() { |ancestor| ancestor.Stay(ancestor[key]) if ancestor.has?(key) }
          end

          def default(element, inherited) = element.has?(:xmlns) ? element[:xmlns] : inherited

          def svg_name(element, namespace)
            name = element.name
            qualified = name.to_s
            if qualified.include?(":")
              prefix, local = qualified.split(":", 2)
              return local.to_sym if binding(element, :"xmlns:#{prefix}") == SVG_URI

              return
            end

            name if namespace.to_s.empty? || namespace == SVG_URI
          end
        end

        private_constant :NamespaceScope

        # Validates this subtree against the SVG standard metadata.
        # @return [Sevgi::Graphics::Element] self
        # @raise [Sevgi::ValidationError] when SVG validation fails
        def Validate
          scope = NamespaceScope.new(self)
          Traverse do |element, depth|
            name = scope.enter(element, depth)
            next unless name

            attributes, children = element.attributes.keys, scope.children(element, depth)
            Standard.conform(name, attributes:, cdata: element.CData(), elements: children)
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
