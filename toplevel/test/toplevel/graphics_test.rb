# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  class ToplevelGraphicsTest < Minitest::Test
    def test_toplevel_graphics_canvas
      assert(SVG.is_a?(::Module))
      assert_equal(SVG, Graphics)
    end

    def test_toplevel_mixin
      klass = Class.new do
        include ::Sevgi
      end

      obj = klass.new
      doc = Graphics.document(:mixin)

      begin
        Sevgi::Graphics::Mixtures.const_set(:Foo, Module.new)
        obj.Mixin(:Foo, doc)
        assert_raises(NoMethodError) { Mixin(:Foo, doc) }
      ensure
        Sevgi::Graphics::Mixtures.send(:remove_const, :Foo)
      end
    end
  end
end
