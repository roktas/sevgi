# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # DSL helpers for expanding callable modules into SVG symbols.
      module Symbols
        # Renders module callables as symbols under defs.
        # @param mod [Module] callable drawing module
        # @param args [Array<Object>] callable arguments
        # @param kwargs [Hash] defs attributes
        # @yield [name] converts each callable name to a symbol id
        # @yieldparam name [Symbol] callable method name
        # @yieldreturn [String, Symbol] symbol id
        # @return [Sevgi::Graphics::Element] defs element
        # @raise [Sevgi::ArgumentError] when mod is not a plain module
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
