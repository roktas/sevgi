# frozen_string_literal: true

require "sevgi/graphics"

module Sevgi
  Callable = Graphics::Callable

  module External
    def Canvas(...)   = Graphics.Canvas(...)

    def Doc(name = :default, preambles: [], attributes: {})
      Class.new(Graphics::Document::Base) { document(name, preambles:, attributes:) }
    end

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

    def svg(...)
      SVG(:html, ...)
    end
  end
end
