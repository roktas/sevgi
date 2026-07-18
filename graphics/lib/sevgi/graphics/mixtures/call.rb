# frozen_string_literal: true

module Sevgi
  module Graphics
    # Callable drawing module support.
    # Extend a plain Ruby module with this API to make its public instance methods callable drawing steps. Name the
    # method `call` when the module has a single drawing step; use descriptive method names when it has multiple steps.
    # Base blocks add argument-independent shared SVG content once per invocation before the public drawing methods.
    # Invocation does not change the configured module, so it may be frozen after its drawing steps are defined. A
    # duplicate or clone owns an independent configuration snapshot; freezing a callable module prevents later base
    # registration while leaving invocation available.
    # @example Define and call a drawing module
    #   Widget = Module.new do
    #     extend Sevgi::Graphics::Module
    #
    #     base { css ".widget" => { fill: "red" } }
    #
    #     def call(id)
    #       draw id
    #     end
    #
    #     private
    #
    #     def draw(id) = rect id:, class: "widget"
    #   end
    #
    #   Sevgi::Graphics.SVG { Call Widget, "box" }
    module Module
      # Ephemeral callable receiver that preserves a module's normal method lookup while forwarding drawing operations
      # to the current element.
      # @api private
      class Context < ::BasicObject
        # Creates a delegated callable receiver.
        # @param callable [Module] callable module
        # @param receiver [Sevgi::Graphics::Element] current drawing element
        # @return [void]
        def initialize(callable, receiver)
          @callable = callable
          @receiver = receiver
        end

        # Reports methods available through either callable composition or the drawing element.
        # @param name [Symbol, String] method name
        # @param include_private [Boolean] whether private methods count
        # @return [Boolean]
        def respond_to?(name, include_private = false) = respond_to_missing?(name, include_private)

        private

        # Reports methods available through callable composition or receiver delegation.
        # @param name [Symbol, String] method name
        # @param include_private [Boolean] whether private methods count
        # @return [Boolean]
        def respond_to_missing?(name, include_private = false)
          @callable.public_method_defined?(name) ||
            (include_private &&
              (@callable.protected_method_defined?(name) || @callable.private_method_defined?(name))) ||
            @receiver.respond_to?(name, include_private)
        end

        # Forwards operations outside the callable module's lookup chain to the drawing element.
        # @param name [Symbol] missing method name
        # @param arguments [Array<Object>] positional arguments
        # @param keywords [Hash] keyword arguments
        # @param block [Proc, nil] forwarded block
        # @return [Object] delegated result
        def method_missing(name, *arguments, **keywords, &block)
          @receiver.__send__(name, *arguments, **keywords, &block)
        end
      end

      private_constant :Context

      # Registers argument-independent shared drawing steps. Every invocation runs inherited base blocks parent-first,
      # then locally registered base blocks in registration order, before the module's public drawing methods. The block
      # runs once in the current element context and does not receive the invocation arguments.
      # @yield evaluates the drawing DSL in the current element context
      # @yieldreturn [Object] ignored block result
      # @return [nil]
      # @raise [Sevgi::ArgumentError] when no block is given
      # @raise [FrozenError] when the callable module is frozen
      def base(&block)
        raise ::FrozenError, "can't modify frozen callable module" if frozen?

        ArgumentError.("Block required") unless block

        own_configuration
        @sevgi_bases << block
        nil
      end

      class << self
        private

        # Initializes callable module state.
        # @param base [Module] extended module
        # @return [void]
        def extended(base)
          base.instance_variable_set(:@sevgi_bases, [])
          base.instance_variable_set(:@sevgi_callables, base.public_instance_methods(false))
          base.instance_variable_set(:@sevgi_configuration_owner, base.object_id)
        end

        # Returns an owned snapshot of inherited and local base blocks in execution order.
        # @param mod [Module] module extended with {Sevgi::Graphics::Module}
        # @return [Array<Proc>] parent-first base blocks followed by local base blocks
        # @raise [Sevgi::ArgumentError] when mod is not a callable drawing module
        def bases(mod)
          validate(mod)

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
        #   @param mod [Module] module extended with {Sevgi::Graphics::Module}
        #   @param receiver [Sevgi::Graphics::Element] receiver element
        #   @param args [Array<Object>] callable arguments
        #   @param kwargs [Hash] callable keyword arguments
        #   @return [Object, nil] last callable return value
        #   @raise [Sevgi::ArgumentError] when mod is not a callable drawing module
        def call(mod, receiver, ...)
          methods = callables(mod)
          context = context(mod, receiver)
          bases(mod).each { context.instance_exec(&it) }

          invoke(context, receiver, methods, ...)
        end

        # Returns the methods that should be executed for a callable module.
        # @param mod [Module] module extended with {Sevgi::Graphics::Module}
        # @return [Array<UnboundMethod>]
        # @raise [Sevgi::ArgumentError] when mod is not a callable drawing module
        def callables(mod)
          validate(mod)

          callable_names(mod).uniq.filter_map do |name|
            mod.instance_method(name) if mod.public_method_defined?(name)
          end
        end

        def callable_names(mod)
          mod.ancestors.reverse_each.flat_map do |ancestor|
            if ancestor.instance_variable_defined?(:@sevgi_callables)
              ancestor.instance_variable_get(:@sevgi_callables) + ancestor.public_instance_methods(false)
            else
              ancestor.public_instance_methods(false)
            end
          end
        end

        def context(mod, receiver)
          ::Class.new(Context) { include(mod) }.new(mod, receiver)
        end

        def invoke(context, receiver, methods, ...)
          result = methods.map { context.__send__(it.name, ...) }.last
          result.equal?(context) ? receiver : result
        end

        def validate(mod)
          return mod if mod.instance_of?(::Module) && mod.is_a?(Graphics::Module)

          ArgumentError.("Callable drawing module must extend Sevgi::Graphics::Module: #{mod}")
        end
      end

      private

      # Gives a duplicated callable module independent configuration containers.
      # @param original [Module] source callable module
      # @return [void]
      # @api private
      def initialize_dup(original)
        super
        copy_configuration(original)
      end

      # Gives a cloned callable module independent configuration containers.
      # @param original [Module] source callable module
      # @param freeze [Boolean] whether Ruby preserves the source frozen state
      # @return [void]
      # @api private
      def initialize_clone(original, freeze: true)
        super
        copy_configuration(original)
      end

      def copy_configuration(original)
        @sevgi_bases = original.instance_variable_get(:@sevgi_bases).dup
        @sevgi_callables = original.instance_variable_get(:@sevgi_callables).dup
        @sevgi_configuration_owner = object_id
      end

      def own_configuration
        return if @sevgi_configuration_owner == object_id

        @sevgi_bases = @sevgi_bases.dup
        @sevgi_callables = @sevgi_callables.dup
        @sevgi_configuration_owner = object_id
      end

      # Tracks newly defined methods as callable drawing candidates.
      # Invocation runs unique methods that are still public, preserving tracked definition order.
      # @param method [Symbol] method name Ruby reports as added
      # @return [Array<Symbol>, nil]
      def method_added(method)
        super

        own_configuration
        @sevgi_callables << method
      end

      private :copy_configuration, :own_configuration
    end

    # Recursive callable drawing module support. Extend a module with this API when it and the modules defined beneath
    # it form a callable drawing namespace. Existing and subsequently defined descendants receive the same recursive
    # contract. Classes, autoloads, and modules aliased from another namespace are left unchanged.
    # @example Define a callable drawing namespace
    #   module Icons
    #     extend Sevgi::Graphics::Modules
    #
    #     module Alert
    #       base { css ".alert" => { fill: "red" } }
    #
    #       def call(id)
    #         circle id:, class: "alert", r: 5
    #       end
    #     end
    #   end
    #
    #   Sevgi::Graphics.SVG { Call Icons::Alert, "warning" }
    # @see Sevgi::Graphics::Module
    module Modules
      # Propagates the recursive contract when a module constant is added.
      # @api private
      module Propagation
        private

        def const_added(name)
          super
          Graphics::Modules.__send__(:adopt, self, name)
        end
      end

      private_constant :Propagation

      class << self
        private

        # Applies the local callable contract and adopts owned descendants.
        # @param base [Module] extended module
        # @return [void]
        def extended(base)
          base.extend(Graphics::Module)
          base.singleton_class.prepend(Propagation) unless base.singleton_class < Propagation
          base.constants(false).each { adopt(base, it) }
        end

        # Applies this contract to an owned module constant without resolving autoloads or following aliases.
        # @param owner [Module] constant owner
        # @param name [Symbol] constant name
        # @return [Module, nil] adopted module, or nil when the constant is outside the contract
        def adopt(owner, name)
          return if owner.autoload?(name, false)

          child = owner.const_get(name, false)
          return unless child.instance_of?(::Module)
          return unless child.name == "#{owner}::#{name}"

          child.extend(self) unless child.is_a?(self)
        end
      end
    end

    module Mixtures
      # DSL helpers for invoking callable drawing modules.
      module Call
        # @overload Call(mod, *args, **kwargs)
        #   Runs a callable drawing module in the current element context.
        #   @param mod [Module] module extended with {Sevgi::Graphics::Module}
        #   @param args [Array<Object>] callable arguments
        #   @param kwargs [Hash] callable keyword arguments
        #   @return [Object, nil] last callable return value
        #   @raise [Sevgi::ArgumentError] when mod is not a callable drawing module
        def Call(mod, ...)
          Graphics::Module.__send__(:call, mod, self, ...)
        end

      end
    end
  end
end
