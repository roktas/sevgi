# frozen_string_literal: true

require "sevgi/function"

require_relative "graphics/attribute"
require_relative "graphics/auxiliary"
require_relative "graphics/element"
require_relative "graphics/mixtures"

require_relative "graphics/document"

require_relative "graphics/version"

module Sevgi
  module Graphics
    def canvas(...)
      Graphics::Canvas.from_paper(...)
    end

    def document(name = Undefined, preambles: [], attributes: {})
      Class.new(Graphics::Document::Base) { document(name, preambles:, attributes:, register: name != Undefined) }
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
