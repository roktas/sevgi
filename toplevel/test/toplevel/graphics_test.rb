# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  class ToplevelGraphicsTest < Minitest::Test
    def test_svg_is_an_independent_facade
      assert_same(Sevgi::SVG, ::SVG)
      refute_same(Graphics, ::SVG)
    end

    def test_svg_facade_exposes_graphics_constants
      expected = %i[
        Attributes
        Canvas
        Content
        Document
        Element
        LintError
        Margin
        Mixtures
        Module
        Modules
        Paper
        VERSION
      ]

      assert_equal(expected, ::SVG.constants(false).sort)
      (expected - [:VERSION]).each do |name|
        assert_same(Graphics.const_get(name, false), ::SVG.const_get(name, false))
      end

      assert_same(Sevgi::VERSION, ::SVG::VERSION)
    end

    def test_svg_facade_exposes_capitalized_operations
      expected = %i[
        Canvas
        Decompile
        DecompileFile
        Derender
        DerenderFile
        Document
        Document!
        Evaluate
        EvaluateChildren
        EvaluateChildrenFile
        EvaluateFile
        Grid
        Load
        Mixin
        Module
        Paper
        Paper!
      ]

      assert_equal(expected, ::SVG.singleton_methods(false).sort)
      assert_instance_of(Graphics::Canvas, ::SVG.Canvas(width: 4, height: 2))
      assert_operator(::SVG.Document(attributes: {}), :<, Graphics::Document::Base)
    end

    def test_svg_facade_builds_callable_module
      yielded = nil
      callable = ::SVG.Module() do |mod|
        yielded = mod

        base { rect(id: "base") }

        define_method(:call) do |value, &content|
          text(value, &content)
        end

        define_method(:helper) { :private }
        private(:helper)
      end

      drawing = Graphics.SVG(:minimal) do
        Call(callable, "hello") { tspan("world") }
      end

      assert_same(callable, yielded)
      assert_instance_of(::Module, callable)
      assert(callable.is_a?(Graphics::Module))
      refute(callable.is_a?(Graphics::Modules))
      assert_includes(callable.private_instance_methods(false), :helper)
      assert_equal(
        <<~SVG
          <svg>
            <rect id="base"/>
            <text>hello<tspan>world</tspan></text>
          </svg>
        SVG
          .chomp,
        drawing.Render()
      )
    end

    def test_svg_facade_builds_empty_callable_module
      callable = ::SVG.Module()

      assert_instance_of(::Module, callable)
      assert(callable.is_a?(Graphics::Module))
      assert_nil(Graphics.SVG(:minimal).Call(callable))
    end

    def test_svg_facade_omits_component_helpers
      %i[SVG canvas document document! paper paper!].each do |name|
        refute_respond_to(::SVG, name)
      end
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

    def test_toplevel_builds_canvas_and_document_profiles
      canvas = Sevgi.Canvas(width: 4, height: 2)
      profile = Sevgi.Document(attributes: {viewBox: "0 0 4 2"})

      assert_instance_of(Graphics::Canvas, canvas)
      assert_operator(profile, :<, Graphics::Document::Base)
      assert_equal("0 0 4 2", Sevgi.SVG(profile)[:viewBox])
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
