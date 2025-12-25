# frozen_string_literal: true

require_relative "../test_helper"

module Sevgi
  class ExternalGraphicsTest < Minitest::Test
    def test_external_graphics_canvas
      klass = Class.new do
        include ::Sevgi
      end
      canvas = klass.new.Canvas(width: 3, height: 5)
      assert_instance_of(Graphics::Canvas, canvas)
      assert_raises(NoMethodError) { Canvas(width: 3, height: 5) }
    end

    def test_external_graphics_doc
      klass = Class.new do
        include ::Sevgi
      end
      doc = klass.new.Doc(:foo)
      assert(doc < Graphics::Document::Base)
      assert_raises(NoMethodError) { Doc(:foo) }
    end

    def test_external_graphics_paper
      klass = Class.new do
        include ::Sevgi
      end
      paper = klass.new.Paper(3, 5, :xyz)
      assert_equal(:xyz, paper)
      assert_raises(NoMethodError) { Paper(3, 5, :xyz) }
    end

    def test_external_graphics_paper_bang
      klass = Class.new do
        include ::Sevgi
      end
      paper = klass.new.Paper!(3, 5, :abc)
      assert_equal(:abc, paper)
      assert_raises(NoMethodError) { Paper!(3, 5, :abc) }
    end

    def test_external_graphics_mixin
      klass = Class.new do
        include ::Sevgi
      end

      obj = klass.new
      doc = obj.Doc(:mixin)

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
