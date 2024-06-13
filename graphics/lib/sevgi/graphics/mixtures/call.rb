# frozen_string_literal: true

module Sevgi
  module Graphics
    module Callable
      def method_added(method)
        callables << method if public_method_defined?(method)
      end

      def self.extended(base)
        base.instance_exec do
          @callables = []
          class << self
            attr_reader :callables
          end
        end
      end

      class << self
        def call(mod, receiver, ...)
          tap do
            callables(mod).each { it.bind(receiver).call(...) }
          end
        end

        def callables(mod)
          raise(ArgumentError, "Must be a module: #{mod}") unless mod.instance_of?(::Module)

          (mod.respond_to?(:callables) ? mod.callables : mod.instance_methods).map { mod.instance_method(it) }
        end
      end
    end

    module Mixtures
      module Call
        module InstanceMethods
          def Call(mod, ...)
            Callable.call(mod, self, ...)
          end

          private

          # rubocop:disable Metrics/MethodLength
          def CallWithin(mod, container, element, *args, **kwargs, &block)
            raise(ArgumentError, "Must be a module: #{mod}") unless mod.instance_of?(::Module)

            kwargs = kwargs.merge(id: F.demodulize(mod).to_sym) unless kwargs.key?(:id)

            public_send(container, **kwargs) do
              Callable.callables(mod).each do |method|
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
end
