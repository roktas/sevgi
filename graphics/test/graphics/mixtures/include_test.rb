# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class IncludeTest < Minitest::Test
        def test_include_delegates_to_evaluate_file
          receiver = SVG(:minimal)
          calls = []

          ::Sevgi::Derender.stub(:evaluate_file, -> (file, target, id:) { calls << [file, target, id] }) do
            receiver.Include("source.svg", "node")
          end

          assert_equal([["source.svg", receiver, "node"]], calls)
        end

        def test_include_children_delegates_to_children
          receiver = SVG(:minimal)
          calls = []

          ::Sevgi::Derender.stub(:evaluate_file_children, -> (file, target, id:) { calls << [file, target, id] }) do
            receiver.IncludeChildren("source.svg", "node")
          end

          assert_equal([["source.svg", receiver, "node"]], calls)
        end
      end
    end
  end
end
