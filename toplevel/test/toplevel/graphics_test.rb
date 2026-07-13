# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  class ToplevelGraphicsTest < Minitest::Test
    def test_toplevel_exports_graphics_module
      assert(SVG.is_a?(::Module))
      assert_equal(SVG, Graphics)
    end

    def test_toplevel_mixin_stays_instance_scoped
      klass = Class.new do
        include(::Sevgi)
      end

      obj = klass.new
      doc = Graphics.document(:mixin, attributes: {})

      begin
        Sevgi::Graphics::Mixtures.const_set(:Foo, Module.new)
        assert_nil(obj.Mixin(:Foo, doc))
        assert_raises(NoMethodError) { Mixin(:Foo, doc) }
      ensure
        Sevgi::Graphics::Mixtures.send(:remove_const, :Foo)
      end
    end

    def test_toplevel_mixin_accepts_anonymous_block
      klass = Class.new do
        include(::Sevgi)
      end

      doc = Graphics.document(:anonymous_mixin, attributes: {})
      extension = klass.new.Mixin(doc) do
        define_method(:Badge) do
          rect(id: "badge")
        end
      end

      assert_instance_of(Module, extension)
      assert_equal("badge", doc.root.Badge()[:id])
    end

    def test_toplevel_mixin_returns_named_anonymous_extension
      klass = Class.new { include(::Sevgi) }
      doc = Graphics.document(:named_anonymous_mixin, attributes: {})

      begin
        Sevgi::Graphics::Mixtures.const_set(:Empty, Module.new)
        extension = klass.new.Mixin(:Empty, doc) { define_method(:Mark) { circle(id: "mark") } }

        assert_instance_of(Module, extension)
        assert_equal("mark", doc.root.Mark()[:id])
      ensure
        Sevgi::Graphics::Mixtures.send(:remove_const, :Empty)
      end
    end
  end
end
