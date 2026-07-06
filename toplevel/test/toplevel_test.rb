# frozen_string_literal: true

require_relative "test_helper"

module Sevgi
  class ToplevelTest < Minitest::Test
    def test_toplevel_exposes_expected_methods
      assert_equal(
        %i[
          Decompile
          Derender
          Grid
          Load
          Mixin
          Paper
          Paper!
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
        Toplevel::Function,
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
      mod = Module.new
      mod.extend(::Sevgi)

      [
        true,
        mod.respond_to?(:Paper),
        true,
        mod.respond_to?(:Load),
        Toplevel::Function,
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
  end
end
