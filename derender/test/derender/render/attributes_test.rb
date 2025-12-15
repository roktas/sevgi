# frozen_string_literal: true

require_relative "../../test_helper"

module Sevgi
  module Derender
    module Render
      class AttributesTest < Minitest::Test
        def test_simple
          hash = { "foo" => "fff", "b ar" => "bbb" }

          actual   = Render.attributes(hash)
          expected = 'foo: "fff", "b ar": "bbb"'

          assert_equal(expected, actual)
        end

        def test_with_hash
          hash = { "foo" => "fff", "b ar" => "bbb", "baz" => { "qu ux" => 19, "bat" => "b a t " } }

          actual   = Render.attributes(hash)
          expected = 'foo: "fff", "b ar": "bbb", baz: { "qu ux": 19, bat: "b a t " }'

          assert_equal(expected, actual)
        end

        def test_with_style
          hash = { "foo" => "fff", "style" => "color: red; display: none" }

          actual   = Render.attributes(hash)
          expected = 'foo: "fff", style: { color: "red", display: "none" }'

          assert_equal(expected, actual)
        end

        def test_key_order
          hash = { "foo" => "fff", "inkscape:label" => "label", "id" => "bbb", "baz" => 19, "class" => "ccc", "style" => "color: red; display: none", "hmm" => "hhh" }

          actual   = Render.attributes(hash)
          expected = 'id: "bbb", "inkscape:label": "label", class: "ccc", foo: "fff", baz: 19, hmm: "hhh", style: { color: "red", display: "none" }'

          assert_equal(expected, actual)
        end
      end
    end
  end
end
