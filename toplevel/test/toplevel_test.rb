# frozen_string_literal: true

require_relative "test_helper"

module Sevgi
  class ToplevelTest < Minitest::Test
    def test_toplevel_exposes_expected_methods
      assert_equal(
        %i[
          Decompile
          DecompileFile
          Derender
          DerenderFile
          Evaluate
          EvaluateChildren
          EvaluateChildrenFile
          EvaluateFile
          Grid
          Load
          Mixin
          Paper
          Paper!
          SVG
        ],
        Toplevel.public_instance_methods(false).sort
      )
      assert_empty(Toplevel.private_instance_methods(false))
      assert_empty(Toplevel.protected_instance_methods(false))
    end

    def test_include_installs_methods_and_constants
      klass = Class.new do
        include(::Sevgi)
      end

      object = klass.new

      [
        true,
        object.respond_to?(:Paper),
        true,
        object.respond_to?(:Load),
        Toplevel,
        object.method(:SVG).owner,
        Function,
        klass.const_get(:F),
        Geometry,
        klass.const_get(:Geometry),
        Geometry::Origin,
        klass.const_get(:Origin),
        Sundries::Export,
        klass.const_get(:Export)
      ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
    end

    def test_extend_installs_methods_and_constants
      mod = ::Module.new
      mod.extend(::Sevgi)

      [
        true,
        mod.respond_to?(:Paper),
        true,
        mod.respond_to?(:Load),
        Toplevel,
        mod.method(:SVG).owner,
        Function,
        mod.const_get(:F),
        Geometry,
        mod.const_get(:Geometry),
        Geometry::Origin,
        mod.const_get(:Origin),
        Sundries::Export,
        mod.const_get(:Export)
      ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
    end

    def test_include_is_idempotent
      klass = Class.new

      _out, err = capture_io do
        2.times { klass.send(:include, ::Sevgi) }
      end

      assert_empty(err)
    end

    def test_constants_preserves_module_reflection
      assert_instance_of(Array, Toplevel.constants)
      assert_instance_of(Array, Toplevel.constants(false))
    end

    def test_include_preserves_existing_constants
      klass = Class.new
      klass.const_set(:F, :existing)

      _out, err = capture_io do
        klass.send(:include, ::Sevgi)
      end

      [
        :existing,
        klass.const_get(:F),
        Geometry,
        klass.const_get(:Geometry)
      ].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
      assert_empty(err)
    end
  end
end
