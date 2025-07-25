# frozen_string_literal: true

require_relative "internal"

module Sevgi
  # Externals management DSL for consumers

  module External
    @constants = {}

    class << self
      private

        def Promote(constant, symbol = Undefined)
          @constants[Undefined.default(symbol, constant.to_s.split("::").last.to_sym)] = constant
        end
    end

    def Extern(*modules, &block)
      ::Sevgi::External.tap do |external|
        external.module_exec(&block)
        modules.each { external.include(it) }
        ::Sevgi.extend(external)
      end
    end

    def Extern!(receiver, ...)
      receiver.send(:include, Extern(...))
    end

    def self.included(base)
      return if base.instance_variable_defined?("@_external_included_")

      super

      @constants.each { |args| base.const_set(*args) }

      base.instance_variable_set("@_external_included_", true)
    end
  end

  extend External

  # Externals for Graphics

  require "sevgi/graphics"

  Callable = Graphics::Callable

  module External
    def Paper(width, height, name = :custom, unit: "mm")
      name.tap { Graphics::Paper.define(name, width:, height:, unit:) unless Graphics::Paper.exist?(name) }
    end

    def Paper!(width, height, name = :custom, unit: "mm")
      name.tap { Graphics::Paper.define(name, width:, height:, unit:) }
    end

    def Mixin(mod, document = Graphics::Document::Base, &block)
      document.mixture(mod)
      document.mixture(::Module.new(&block)) if block
    end

    def SVG(...)
      Graphics.SVG(...)
    end
  end

  # Externals for Geometry

  require "sevgi/geometry"

  module External
    Promote Geometry
    Promote Geometry::Origin, :Origin
  end

  # Other externals

  module External
    def Load(*files)
      start = ::File.dirname(caller_locations(1..1).first.path)

      files.each do |file|
        location = Sevgi.locate(file, start, exclude: start)

        Sandbox.load(location.file)
      end
    end

    module Function
      extend Sevgi::Function::Math
    end

    Promote Function, :F
  end
end
