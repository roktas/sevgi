# frozen_string_literal: true

module Sevgi
  # Base class for SVG standard validation errors.
  class ValidationError < Error
    # Builds a validation error with a context label and offending values.
    # @param context [Object] validation context included in the error message
    # @param args [Array<Object>, Object] invalid values included in the error message
    # @return [void]
    def initialize(context, args = [])
      @context = context
      @args = Array(args)

      super()
    end

    # Raises this validation error class.
    # @param context [Object] validation context included in the error message
    # @param args [Array<Object>, Object] invalid values included in the error message
    # @return [void]
    # @raise [Sevgi::ValidationError] always raises an instance of this class
    def self.call(context, args = [])
      raise new(context, args)
    end

    # Builds a validation error subclass with a fixed message fragment.
    # @param message [String] message fragment placed after the validation context
    # @return [Class<Sevgi::ValidationError>] validation error subclass
    def self.variant(message)
      Class.new(self) do
        define_method(:message) do
          [@context, message]
            .tap do |messages|
              messages << @args.map { "'#{it}'" }.join(", ") unless @args.empty?
            end
            .join(": ")
        end
      end
    end
  end

  # Raised when an element contains invalid attributes.
  InvalidAttributesError = ValidationError.variant("Invalid attribute(s)")
  # Raised when an element contains invalid child elements.
  InvalidElementsError = ValidationError.variant("Invalid element(s)")
  # Raised when character data appears where the SVG model forbids it.
  UnallowedCDataError = ValidationError.variant("Character data not allowed")
  # Raised when an element contains disallowed child elements.
  UnallowedElementsError = ValidationError.variant("Element(s) not allowed")
  # Raised when a conditional SVG content model requirement is not met.
  UnmetConditionError = ValidationError.variant("Condition unmet for the element")
end
