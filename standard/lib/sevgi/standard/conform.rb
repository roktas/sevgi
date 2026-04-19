# frozen_string_literal: true

module Sevgi
  module Standard
    class Conform
      require_relative "model"

      attr_reader :element, :spec

      def initialize(element)
        InvalidElementsError.(element) unless (@spec = Specification[@element = element])

        raise(ModelError, "No model specified: #{element}") unless spec[:model]
        raise(ModelError, "Model unimplemented: #{spec[:model]}") unless Model.const_defined?(spec[:model])

        extend(Model.const_get(spec[:model]))

        raise(NoMethodError, "#{self.class}#apply must be implemented") unless respond_to?(:apply)
      end

      def call(attributes: nil, cdata: nil, elements: nil)
        if attributes
          unrecognized = attributes - spec[:attributes]

          InvalidAttributesError.(element, unrecognized) unless unrecognized.empty?
        end

        apply(cdata:, elements:)

        true
      end

      @cache = {}

      def self.call(element, attributes: nil, cdata: nil, elements: nil)
        Element.ignore?(element) or (@cache[element] ||= new(element)).call(
          attributes: Attribute.concerns(attributes),
          elements:   Element.concerns(elements),
          cdata:
        )
      end
    end

    private_constant :Conform, :Model
  end
end
