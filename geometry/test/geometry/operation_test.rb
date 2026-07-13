# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  module Geometry
    class OperationTest < Minitest::Test
      def test_operation_exposes_registered_methods
        %i[
          align
          alignment
          sweep
          sweep!
        ].each do |operation|
          assert_respond_to(Operation, operation)
        end

        refute_respond_to(Operation, :unisweep)
      end

      def test_operation_hides_registration_surface
        refute_respond_to(Operation, :register)
        refute_includes(Operation.constants(false), :Align)
        refute_includes(Operation.constants(false), :Sweep)
        refute_respond_to(Operation.const_get(:Sweep, false), :unisweep)
      end

      def test_inapplicable_operation_error_is_clear
        error = assert_raises(Operation::OperationInapplicableError) do
          Operation.sweep(Element.allocate, initial: Origin, angle: 0, step: 1)
        end

        assert_match(/Operation not applicable/, error.message)
      end
    end
  end
end
