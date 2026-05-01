# frozen_string_literal: true

module Sevgi
  class ValidationError < Error
    def initialize(context, args = [])
      @context = context
      @args    = Array(args)

      super()
    end

    def self.call(context, args = []) = raise(new(context, args))

    def self.variant(message)
      Class.new(self) do
        define_method(:message) do
          [ @context, message  ].tap do |messages|
            messages << @args.map { "'#{it}'" }.join(", ") unless @args.empty?
          end.join(": ")
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
