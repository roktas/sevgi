# frozen_string_literal: true

module Sevgi
  module Graphics
    # Callable drawing module support.
    # Extend a plain Ruby module with this API to make its public instance methods callable drawing steps.
    # @example Define and call a drawing module
    #   Widget = Module.new do
    #     extend Sevgi::Graphics::Module
    #
    #     def item(id)
    #       rect(id:)
    #     end
    #   end
    #
    #   SVG { Call(Widget, "box") }
    module Module
      # Tracks newly defined methods as callable drawing candidates.
      # Invocation runs unique methods that are still public, preserving tracked definition order.
      # @param method [Symbol] method name Ruby reports as added
      # @return [Array<Symbol>, nil]
      def method_added(method)
        super

        _callables << method if public_method_defined?(method)
      end

      # Class-level DSL for callable drawing modules.
      # @api private
      module DSL
        # Registers a before or after hook.
        # @param after [Boolean] true to register an after hook
        # @return [Array<Proc>] hook list
        def call(after = false, &block) = ((after ? _afters : _befores) << block)
      end

      private_constant :DSL

      # Initializes callable module state.
      # @param base [Module] extended module
      # @return [void]
      def self.extended(base)
        base.instance_exec do
          @_callables = []
          @_befores = []
          @_afters = []

          class << self
            attr_reader :_callables, :_befores, :_afters
          end

          extend(DSL)
        end
      end

      # @overload call(mod, receiver, *args, **kwargs)
      #   Runs module hooks and callables against a receiver.
      #   @param mod [Module] callable module
      #   @param receiver [Sevgi::Graphics::Element] receiver element
      #   @param args [Array<Object>] callable arguments
      #   @param kwargs [Hash] callable keyword arguments
      #   @return [Object, nil] last callable return value
      #   @raise [Sevgi::ArgumentError] when mod is not a plain module
      def self.call(mod, receiver, ...)
        mod._befores.each { receiver.Within(receiver, &it) } if mod.respond_to?(:_befores) && mod._befores
        # return last callable return value
        callables(mod).map { it.bind(receiver).call(...) }.last.tap do
          mod._afters.each { receiver.Within(receiver, &it) } if mod.respond_to?(:_afters) && mod._afters
        end
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
        tracked = mod.ancestors.reverse_each.filter_map do |ancestor|
          ancestor._callables if ancestor.respond_to?(:_callables)
        end

        return tracked.flatten unless tracked.empty?

        mod.public_instance_methods
      end

      private_class_method :callable_names
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
          Graphics::Module.call(mod, self, ...)
        end

        private

        # rubocop:disable Metrics/MethodLength
        def CallWithin(mod, container, element, *args, **kwargs, &block)
          ArgumentError.("Must be a module: #{mod}") unless mod.instance_of?(::Module)

          kwargs = kwargs.merge(id: F.demodulize(mod).to_sym) unless kwargs.key?(:id)

          mod._befores.each { Within(self, &it) } if mod.respond_to?(:_befores) && mod._befores

          public_send(container, **kwargs) do
            Graphics::Module.callables(mod).each do |method|
              public_send(element) do
                Within(self, method.name, self, &block)

                method.bind(self).call(*args)
              end
            end
          end

          mod._afters.each { Within(self, &it) } if mod.respond_to?(:_afters) && mod._afters

          self
        end
        # rubocop:enable Metrics/MethodLength
      end
    end
  end
end
