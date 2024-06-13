# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Polyfills
        module InstanceMethods
          def layer(...)     = g(...)

          def symbol!(...)   = symbol(...)
        end
      end
    end
  end
end
