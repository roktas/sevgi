# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  class ToplevelDerenderTest < Minitest::Test
    def test_decompile_delegates_to_file_api
      calls = []
      node = Object.new

      ::Sevgi::Derender.stub(
        :decompile_file,
        -> (file, id:) {
          calls << [file, id]
          node
        }
      ) do
        assert_same(node, receiver.Decompile("drawing", "Root"))
      end

      assert_equal([%w[drawing Root]], calls)
    end

    def test_derender_delegates_to_file_api
      calls = []

      ::Sevgi::Derender.stub(
        :derender_file,
        -> (file, id:) {
          calls << [file, id]
          "SVG"
        }
      ) do
        assert_equal("SVG", receiver.Derender("drawing", "Root"))
      end

      assert_equal([%w[drawing Root]], calls)
    end

    private

    def receiver
      Class
        .new do
          include(::Sevgi)
        end
        .new
    end
  end
end
