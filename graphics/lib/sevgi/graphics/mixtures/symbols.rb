# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Symbols
        def Symbols(mod, *args, **kwargs, &block)
          CallWithin(mod, :defs, :symbol, *args, **kwargs) do |name, element|
            element[:id] = block ? block.call(name) : name.to_s.split("_").join("-")
            title(name.to_s.split("_").map(&:capitalize).join(" "))
          end
        end
      end
    end
  end
end
