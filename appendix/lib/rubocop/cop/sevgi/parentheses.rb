# frozen_string_literal: true

require "rubocop/cop/style/method_call_with_args_parentheses"

module RuboCop
  # RuboCop's custom-cop namespace.
  module Cop
    module Sevgi
      # Omits optional parentheses from bare DSL-shaped calls and capitalized Sevgi operations.
      #
      # Ordinary Ruby calls with explicit receivers retain their normal style. The inherited RuboCop implementation
      # still preserves parentheses where Ruby syntax or expression binding benefits from them.
      class Parentheses < Style::MethodCallWithArgsParentheses
        # Checks a method call when its shape belongs to the Sevgi drawing vocabulary.
        # @param node [RuboCop::AST::SendNode] method call
        # @return [void]
        def on_send(node)
          return if node.method_name.end_with?("?")

          super if node.receiver.nil? || node.method_name.match?(/\A[A-Z]/)
        end

        alias on_csend on_send
      end
    end
  end
end
