# frozen_string_literal: true

module Sevgi
  module Graphics
    module Callable
      def method_added(method)
        _callables << method if public_method_defined?(method)
      end

      module DSL
        def call(after = false, &block) = ((after ? _after : _befores) << block)
      end

      private_constant :DSL

      def self.extended(base)
        base.instance_exec do
          @_callables = []
          @_befores   = []
          @_afters    = []

          class << self
            attr_reader :_callables, :_befores, :_afters
          end

          extend DSL
        end
      end

      def self.call(mod, receiver, ...)
        mod._befores.each { receiver.Within(receiver, &it) } if mod.respond_to?(:_befores) && mod._befores
        callables(mod).map { it.bind(receiver).call(...) }.last.tap do # return last callable return value
          mod._afters.each { receiver.Within(receiver, &it) } if mod.respond_to?(:_afters) && mod._afters
        end
      end

      def self.callables(mod)
        raise(ArgumentError, "Must be a module: #{mod}") unless mod.instance_of?(::Module)

        (mod.respond_to?(:_callables) ? mod._callables : mod.instance_methods).map { mod.instance_method(it) }
      end
    end

    module Mixtures
      module Call
        def Call(mod, ...)
          Callable.call(mod, self, ...)
        end

        private

          # rubocop:disable Metrics/MethodLength
          def CallWithin(mod, container, element, *args, **kwargs, &block)
            raise(ArgumentError, "Must be a module: #{mod}") unless mod.instance_of?(::Module)

            kwargs = kwargs.merge(id: F.demodulize(mod).to_sym) unless kwargs.key?(:id)

            mod._befores.each { Within(self, &it) } if mod.respond_to?(:_befores) && mod._befores

            public_send(container, **kwargs) do
              Callable.callables(mod).each do |method|
                public_send(element) do
                  Within(self, method.name, self, &block)

                  method.bind(self).call(*args)
                end
              end
            end

            mod._afters.each { Within(self, &it) } if mod.respond_to?(:_afters) && mod._afters

            self
          end
      end
    end
  end
end
