# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # DSL helpers for expanding callable modules into SVG symbols.
      module Symbols
        # Builds one symbol set without adding helper methods to the document DSL.
        # @api private
        class Expansion
          # Creates a symbol expansion.
          # @param receiver [Sevgi::Graphics::Element] parent element
          # @param mod [Module] module extended with {Sevgi::Graphics::Module}
          # @return [void]
          def initialize(receiver, mod)
            @receiver = receiver
            @mod = mod
          end

          # Builds a defs container and populates it from the callable module.
          # @param args [Array<Object>] callable positional arguments
          # @param attributes [Hash] defs attributes
          # @param ids [#call, nil] symbol id mapper
          # @param kwargs [Hash] callable keyword arguments
          # @param block [Proc, nil] callable block argument
          # @return [Sevgi::Graphics::Element] defs element
          # @raise [Sevgi::ArgumentError] when an input channel is invalid
          def call(*args, attributes:, ids:, **kwargs, &block)
            methods = Graphics::Module.__send__(:callables, @mod)
            ArgumentError.("Defs attributes must be a Hash") unless attributes.is_a?(::Hash)
            ArgumentError.("Symbol ids must respond to call") if ids && !ids.respond_to?(:call)

            defaults = @mod.name ? {id: F.demodulize(@mod.name).to_sym} : {}
            attributes = Attribute.defaults(attributes, **defaults)
            @args, @kwargs, @block = args, kwargs, block
            @receiver.defs(**attributes).tap { populate(it, methods, ids) }
          end

          private

          # Adds bases and symbols to a defs element.
          # @param defs [Sevgi::Graphics::Element] defs element
          # @param methods [Array<UnboundMethod>] callable methods
          # @param ids [#call, nil] symbol id mapper
          # @return [void]
          def populate(defs, methods, ids)
            context = Graphics::Module.__send__(:context, @mod, defs)
            Graphics::Module.__send__(:bases, @mod).each { context.instance_exec(&it) }
            methods.each { draw(defs, it, ids) }
          end

          # Adds one callable symbol.
          # @param defs [Sevgi::Graphics::Element] defs element
          # @param method [UnboundMethod] callable method
          # @param ids [#call, nil] symbol id mapper
          # @return [Object, nil] callable return value
          def draw(defs, method, ids)
            name = method.name
            symbol = defs.symbol(id: ids ? ids.call(name) : name.to_s.tr("_", "-"))
            symbol.title(name.to_s.split("_").map(&:capitalize).join(" "))
            context = Graphics::Module.__send__(:context, @mod, symbol)
            Graphics::Module.__send__(:invoke, context, symbol, [method], *@args, **@kwargs, &@block)
          end
        end

        private_constant :Expansion

        # Renders module callables as symbols under defs. Named modules default the defs id to their final constant name;
        # anonymous modules omit the id unless supplied.
        # @param mod [Module] module extended with {Sevgi::Graphics::Module}
        # @param args [Array<Object>] callable arguments
        # Base blocks run once in the defs element before symbols are created. Positional arguments, keyword arguments,
        # and the block are forwarded to each callable.
        # @param attributes [Hash] defs attributes; String and Symbol names are normalized and must not collide
        # @param ids [#call, nil] optional callable mapping each method name to a symbol id
        # @param kwargs [Hash] callable keyword arguments
        # @yield forwarded to each callable
        # @yieldreturn [Object] callable-defined block result
        # @return [Sevgi::Graphics::Element] defs element
        # @raise [Sevgi::ArgumentError] when mod is not a callable drawing module, attributes is not a Hash, or ids is
        #   not callable
        def Symbols(mod, *args, attributes: {}, ids: nil, **kwargs, &block)
          Expansion.new(self, mod).call(*args, attributes:, ids:, **kwargs, &block)
        end
      end
    end
  end
end
