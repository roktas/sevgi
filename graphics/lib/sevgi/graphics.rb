# frozen_string_literal: true

require "sevgi/function"

require_relative "graphics/version"

require_relative "graphics/attribute"
require_relative "graphics/element"
require_relative "graphics/auxilary"
require_relative "graphics/mixtures"
require_relative "graphics/document"


module Sevgi
  module Graphics
    def Canvas(...)
      Graphics::Canvas.(...)
    end

    def SVG(document = :default, canvas = Undefined, **, &block)
      Graphics::Document.(document, canvas, **, &block)
    end

    extend self
  end
end
