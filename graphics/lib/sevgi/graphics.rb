# frozen_string_literal: true

require "sevgi/function"

require_relative "graphics/version"

require_relative "graphics/attribute"
require_relative "graphics/auxilary"
require_relative "graphics/element"
require_relative "graphics/mixtures"

require_relative "graphics/document"


module Sevgi
  module Graphics
    def canvas(...)
      Graphics::Canvas.(...)
    end

    def document(name = :default, preambles: [], attributes: {})
      Class.new(Graphics::Document::Base) { document(name, preambles:, attributes:) }
    end

    def mixin(mod, document = Graphics::Document::Base, &block)
      document.mixture(mod)
      document.mixture(::Module.new(&block)) if block
    end

    def paper(width, height, name = :custom, unit: "mm")
      name.tap { Graphics::Paper.define(name, width:, height:, unit:) unless Graphics::Paper.exist?(name) }
    end

    def paper!(width, height, name = :custom, unit: "mm")
      name.tap { Graphics::Paper.define(name, width:, height:, unit:) }
    end

    def SVG(document = :default, canvas = Undefined, **, &block)
      Graphics::Document.(document, canvas, **, &block)
    end

    extend self
  end

  SVG = Graphics
end
