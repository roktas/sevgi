# frozen_string_literal: true

require "sevgi/graphics"

module Sevgi
  module Toplevel
    def Mixin(mod, document = Graphics::Document::Base, &block)
      document.mixture(mod)
      document.mixture(::Module.new(&block)) if block
    end

    promote Graphics, :SVG
  end
end
