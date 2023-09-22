# frozen_string_literal: true

module Sevgi
  module Standard
    class Conform
      require_relative "model"

      attr_reader :element, :spec

      def initialize(element)
        InvalidElementsError.(element) unless (@spec = Specification[@element = element])

        raise(NotImplementedError, "No model specified: #{element}") unless spec[:model]
        raise(NotImplementedError, "Model unimplemented: #{spec[:model]}") unless Model.const_defined?(spec[:model])

        extend(Model.const_get(spec[:model]))

        raise(NotImplementedError, "Unimplemented apply method: #{spec[:model]}") unless respond_to?(:apply)
      end

      def call(attributes: nil, cdata: nil, elements: nil)
        if attributes
          unrecognized = concerning_attributes(attributes) - spec[:attributes]

          InvalidAttributesError.(element, unrecognized) unless unrecognized.empty?
        end

        apply(cdata:, elements:)

        true
      end

      private

      def concerning_attributes(attributes)
        attributes.reject do |attribute|
          attribute.start_with?("_")                                                                           ||
          attribute == :xmlns                                                                                  ||
          attribute.start_with?("data-")                                                                       ||
          (attribute.to_s.include?(":") && !attribute.start_with?("xlink:") && !attribute.start_with?("xml:"))
        end
      end

      @cache = {}

      class << self
        def call(element, attributes: nil, cdata: nil, elements: nil)
          (@cache[element] ||= new(element)).call(attributes:, cdata:, elements:)
        end
      end
    end

    private_constant :Conform, :Model
  end
end
