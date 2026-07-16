# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  class ToplevelGraphicsTest < Minitest::Test
    def test_toplevel_exports_graphics_module
      assert(SVG.is_a?(::Module))
      assert_equal(SVG, Graphics)
    end

    def test_toplevel_does_not_own_callable_contract_aliases
      refute_includes(Sevgi.constants(false), :Module)
      refute_includes(Sevgi.constants(false), :Modules)
    end

    def test_toplevel_builds_svg_through_every_public_mode
      included = Class.new { include(::Sevgi) }.new

      [
        Toplevel,
        Sevgi.method(:SVG).owner,
        Toplevel,
        included.method(:SVG).owner,
        "<svg>\n  <rect width=\"3\"/>\n</svg>",
        Sevgi.SVG(:minimal) { rect(width: 3) }.Render(),
        "<svg>\n  <circle r=\"2\"/>\n</svg>",
        included.SVG(:minimal) { circle(r: 2) }.Render()
      ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
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
