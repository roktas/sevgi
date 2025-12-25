# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Polyfills
        def layer(...)     = g(...)

        def symbol!(...)   = symbol(...)
      end
    end
  end
end
