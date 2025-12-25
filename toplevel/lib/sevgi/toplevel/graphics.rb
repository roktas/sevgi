# frozen_string_literal: true

require "sevgi/graphics"

module Sevgi
  module Toplevel
    def Canvas(...)
      Graphics.Canvas(...)
    end

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

    Promote Graphics::Callable
  end
end
