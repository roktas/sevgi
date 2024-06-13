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

      def included(base)
        super

        @constants.each { |args| base.const_set(*args) }
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
  end

  extend External

  # Externals for Graphics

  require "sevgi/graphics"

  Callable = Graphics::Callable

  module External
    def Canvas(...)
      Graphics.Canvas(...)
    end

    def Mixin(mod, document = Graphics::Document::Base, &block)
      document.mixture(mod)
      document.mixture(::Module.new(&block)) if block
    end

    def SVG(...)
      Graphics.SVG(...)
    end

    def Verbatim(content)
      Graphics::Content.verbatim(content)
    end

    Promote Callable
  end

  # Externals for Geometry

  require "sevgi/geometry"

  module External
    def Point(...)
      Geometry::Point.new(...)
    end

    Promote Geometry
  end

  # Externals for Standard

  require "sevgi/standard"

  module External
    Promote Standard::Color, :Color
  end

  # Other externals

  EXTENSION = "sevgi"

  module External
    def Load(file)
      start = ::File.dirname(exclude = caller_locations(1..1).first.path)

      raise(Error, "Cannot load a file matching: #{file}") unless (location = Locate.(F.qualify(file, EXTENSION), start, exclude:))

      Sandbox.load(location.file)
    end

    module Function
      extend Sevgi::Function::Math
    end

    Promote Function, :F
  end
end
