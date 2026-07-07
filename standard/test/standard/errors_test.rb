# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Standard
    class ErrorsTest < Minitest::Test
      def test_validation_errors_inherit_sevgi_error
        [
          InvalidAttributesError,
          InvalidElementsError,
          UnallowedCDataError,
          UnallowedElementsError,
          UnmetConditionError
        ].each { assert_operator(it, :<, ::Sevgi::Error) }
      end
    end
  end
end
