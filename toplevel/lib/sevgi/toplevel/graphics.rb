# frozen_string_literal: true

require "sevgi/graphics"

module Sevgi
  module Toplevel
    def Mixin(...) = Graphics::Mixtures.mixin(...)

    def Paper(...) = Graphics.paper(...)

    def Paper!(...) = Graphics.paper!(...)
  end
end
