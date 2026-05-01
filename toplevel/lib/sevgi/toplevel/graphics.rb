# frozen_string_literal: true

require "sevgi/graphics"

module Sevgi
  module Toplevel
    def Mixin(...) = Graphics::Mixtures.mixin(...)

    def Paper(width, height, name = :custom, unit: "mm")
      name.tap { Graphics::Paper.define(name, width:, height:, unit:) unless Graphics::Paper.exist?(name) }
    end

    def Paper!(width, height, name = :custom, unit: "mm")
      name.tap { Graphics::Paper.define(name, width:, height:, unit:) }
    end
  end
end
