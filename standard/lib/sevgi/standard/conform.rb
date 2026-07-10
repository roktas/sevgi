# frozen_string_literal: true

module Sevgi
  module Standard
    # Validates one SVG element usage against the standard data.
    # @api private
    class Conform
      require_relative "model"

      # @return [Symbol] SVG element name
      attr_reader :element

      # @return [Hash] expanded standard specification for the element
      attr_reader :spec

      # Builds a validator for one SVG element.
      # @param element [String, Symbol] SVG element name
      # @return [void]
      # @raise [Sevgi::ArgumentError] when element is not a valid public name
      # @raise [Sevgi::InvalidElementsError] when the element is unknown
      # @raise [Sevgi::PanicError] when the element model is missing or unimplemented
      def initialize(element)
        element = Name.normalize!(element, context: "element")

        InvalidElementsError.(element) unless (@spec = Specification[@element = element])

        PanicError.("No model specified: #{element}") unless spec[:model]
        PanicError.("Model unimplemented: #{spec[:model]}") unless Model.const_defined?(spec[:model])

        extend(Model.const_get(spec[:model]))

        PanicError.("#{self.class}#apply must be implemented") unless respond_to?(:apply)
      end

      # Validates one usage of the configured SVG element.
      # @param attributes [Array<String, Symbol>, nil] attribute names used by the element
      # @param cdata [String, nil] character data content
      # @param elements [Array<String, Symbol>, nil] child element names
      # @return [Boolean] true when the usage conforms
      # @raise [Sevgi::ArgumentError] when any name is not a valid public name
      # @raise [Sevgi::ValidationError] when the usage violates the standard data
      def call(attributes: nil, cdata: nil, elements: nil)
        if attributes
          unrecognized = attributes - spec[:attributes]

          InvalidAttributesError.(element, unrecognized) unless unrecognized.empty?
        end

        apply(cdata:, elements:)

        true
      end

      @cache = {}

      # Validates one SVG element usage, using cached element validators.
      # @param element [String, Symbol] SVG element name
      # @param attributes [Array<String, Symbol>, nil] attribute names used by the element
      # @param cdata [String, nil] character data content
      # @param elements [Array<String, Symbol>, nil] child element names
      # @return [Boolean] true when the usage conforms or the element is ignored
      # @raise [Sevgi::ArgumentError] when any name is not a valid public name
      # @raise [Sevgi::ValidationError] when the usage violates the standard data
      # @raise [Sevgi::PanicError] when the standard data refers to an invalid model
      def self.call(element, attributes: nil, cdata: nil, elements: nil)
        element = Name.normalize!(element, context: "element")
        attributes = Name.list!(attributes, context: "attribute")
        elements = Name.list!(elements || [], context: "element")

        Element.ignore?(element) or
          (@cache[element] ||= new(element)).call(
            attributes: Attribute.concerns(attributes),
            elements: Element.concerns(elements),
            cdata:
          )
      end
    end

    private_constant :Conform, :Model
  end
end
