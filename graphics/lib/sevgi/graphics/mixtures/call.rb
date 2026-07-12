# frozen_string_literal: true

module Sevgi
  module Graphics
    # Callable drawing module support.
    # Extend a plain Ruby module with this API to make its public instance methods callable drawing steps. Name the
    # method `call` when the module has a single drawing step; use descriptive method names when it has multiple steps.
    # Base blocks add argument-independent shared SVG content once per invocation before the public drawing methods.
    # @example Define and call a drawing module
    #   Widget = Module.new do
    #     extend Sevgi::Graphics::Module
    #
    #     base { css(".widget" => { fill: "red" }) }
    #
    #     def call(id)
    #       rect(id:)
    #     end
    #   end
    #
    #   SVG { Call(Widget, "box") }
    module Module
      # Registers argument-independent shared drawing steps. Every invocation runs inherited base blocks parent-first,
      # then locally registered base blocks in registration order, before the module's public drawing methods. The block
      # runs once in the current element context and does not receive the invocation arguments.
      # @yield evaluates the drawing DSL in the current element context
      # @yieldreturn [Object] ignored block result
      # @return [void]
      # @raise [Sevgi::ArgumentError] when no block is given
      def base(&block)
        ArgumentError.("Block required") unless block

        @sevgi_bases << block
        nil
      end

      # Initializes callable module state.
      # @param base [Module] extended module
      # @return [void]
      def self.extended(base)
        base.instance_variable_set(:@sevgi_bases, [])
        base.instance_variable_set(:@sevgi_callables, base.public_instance_methods(false))
      end

      # Returns an owned snapshot of inherited and local base blocks in execution order.
      # @param mod [Module] callable module
      # @return [Array<Proc>] parent-first base blocks followed by local base blocks
      # @raise [Sevgi::ArgumentError] when mod is not a plain module
      def self.bases(mod)
        ArgumentError.("Must be a module: #{mod}") unless mod.instance_of?(::Module)

        mod
          .ancestors
          .reverse_each
          .filter_map do |ancestor|
            ancestor.instance_variable_get(:@sevgi_bases) if ancestor.instance_variable_defined?(:@sevgi_bases)
          end
          .flatten
      end

      # @overload call(mod, receiver, *args, **kwargs)
      #   Runs module bases and callables against a receiver.
      #   @param mod [Module] callable module
      #   @param receiver [Sevgi::Graphics::Element] receiver element
      #   @param args [Array<Object>] callable arguments
      #   @param kwargs [Hash] callable keyword arguments
      #   @return [Object, nil] last callable return value
      #   @raise [Sevgi::ArgumentError] when mod is not a plain module
      def self.call(mod, receiver, ...)
        methods = callables(mod)
        bases(mod).each { receiver.Within(receiver, &it) }

        methods.map { it.bind(receiver).call(...) }.last
      end

      # Returns the methods that should be executed for a callable module.
      # @param mod [Module] callable module
      # @return [Array<UnboundMethod>]
      # @raise [Sevgi::ArgumentError] when mod is not a plain module
      def self.callables(mod)
        ArgumentError.("Must be a module: #{mod}") unless mod.instance_of?(::Module)

        callable_names(mod).uniq.filter_map do |name|
          mod.instance_method(name) if mod.public_method_defined?(name)
        end
      end

      def self.callable_names(mod)
        mod.ancestors.reverse_each.flat_map do |ancestor|
          if ancestor.instance_variable_defined?(:@sevgi_callables)
            ancestor.instance_variable_get(:@sevgi_callables)
          else
            ancestor.public_instance_methods(false)
          end
        end
      end

      private

      # Tracks newly defined methods as callable drawing candidates.
      # Invocation runs unique methods that are still public, preserving tracked definition order.
      # @param method [Symbol] method name Ruby reports as added
      # @return [Array<Symbol>, nil]
      def method_added(method)
        super

        @sevgi_callables << method if public_method_defined?(method)
      end

      private_class_method :bases, :call, :callable_names, :callables, :extended
    end

    module Mixtures
      # DSL helpers for invoking callable drawing modules.
      module Call
        # @overload Call(mod, *args, **kwargs)
        #   Runs a callable drawing module in the current element context.
        #   @param mod [Module] callable module
        #   @param args [Array<Object>] callable arguments
        #   @param kwargs [Hash] callable keyword arguments
        #   @return [Object, nil] last callable return value
        #   @raise [Sevgi::ArgumentError] when mod is not a plain module
        def Call(mod, ...)
          Graphics::Module.__send__(:call, mod, self, ...)
        end

        private

        # rubocop:disable Metrics/MethodLength
        def CallWithin(mod, container, element, *args, **kwargs, &block)
          ArgumentError.("Must be a module: #{mod}") unless mod.instance_of?(::Module)

          kwargs = kwargs.merge(id: F.demodulize(mod).to_sym) unless kwargs.key?(:id)

          Graphics::Module.__send__(:bases, mod).each { Within(self, &it) }

          public_send(container, **kwargs) do
            Graphics::Module.__send__(:callables, mod).each do |method|
              public_send(element) do
                Within(self, method.name, self, &block)

                method.bind(self).call(*args)
              end
            end
          end

          self
        end
        # rubocop:enable Metrics/MethodLength
      end
    end
  end
end
