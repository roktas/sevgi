# frozen_string_literal: true

module Sevgi
  class ValidationError < Error
    def initialize(context, args)
      @context = context
      @args    = Array(args)

      super()
    end

    class << self
      def call(context, args) = raise(new(context, args))

      def variant(message)
        Class.new(self) do
          define_method(:message) { [ @context, message, @args.map { "'#{_1}'" }.join(", ") ].join(": ") }
        end
      end
    end
  end

  InvalidAttributesError = ValidationError.variant("Invalid attribute(s)")
  InvalidElementsError   = ValidationError.variant("Invalid element(s)")
  UnallowedCDataError    = ValidationError.variant("Character data not allowed")
  UnallowedElementsError = ValidationError.variant("Element(s) not allowed")
  UnmetConditionError    = ValidationError.variant("Condition unmet for the element")
end
