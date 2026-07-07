# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Geometry
    class ErrorsTest < Minitest::Test
      def test_error_inherits_sevgi_error
        assert_operator(Error, :<, ::Sevgi::Error)
      end

      def test_operation_errors_inherit_geometry_error
        [
          Operation::OperationError,
          Operation::OperationInapplicableError
        ].each { assert_operator(it, :<, Error) }
      end
    end
  end
end
