# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Graphics
    module Mixtures
      class IncludeTest < Minitest::Test
        def test_include_delegates_to_evaluate_file
          receiver = SVG(:minimal)
          calls = []

          ::Sevgi::Derender.stub(:evaluate_file, -> (file, target, id:, omit:) { calls << [file, target, id, omit] }) do
            receiver.Include("source.svg", :node, omit: %i[id style])
          end

          assert_equal([["source.svg", receiver, :node, %i[id style]]], calls)
        end

        def test_include_children_delegates_to_children
          receiver = SVG(:minimal)
          calls = []

          ::Sevgi::Derender.stub(
            :evaluate_children_file,
            -> (file, target, id:, omit:) { calls << [file, target, id, omit] }
          ) do
            receiver.IncludeChildren("source.svg", "node", omit: :style)
          end

          assert_equal([["source.svg", receiver, "node", :style]], calls)
        end
      end
    end
  end
end
