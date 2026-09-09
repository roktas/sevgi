# frozen_string_literal: true

module Sevgi
  module Graphics
    # Guards callable drawing modules against unchanged recursive invocations.
    # @api private
    module CallableInvocationGuard
      KEY = :sevgi_graphics_callable_invocations
      Frame = Data.define(:module_id, :arguments, :keywords, :block_id)

      private_constant :Frame, :KEY

      private

      def call(mod, receiver, *arguments, **keywords, &block)
        stack = Thread.current[KEY] ||= []
        frame = invocation_frame(mod, arguments, keywords, block)

        if stack.include?(frame)
          name = mod.name || mod.inspect
          ArgumentError.("Recursive callable invocation detected for #{name} with unchanged arguments")
        end

        stack << frame
        pushed = true
        super
      ensure
        if pushed
          stack.pop
          Thread.current[KEY] = nil if stack.empty?
        end
      end

      def invocation_frame(mod, arguments, keywords, block)
        Frame.new(
          module_id: mod.object_id,
          arguments: arguments.map(&:object_id),
          keywords: keywords.sort_by { |key, _| key.to_s }.map { |key, value| [key, value.object_id] },
          block_id: block&.object_id
        )
      end
    end

    Graphics::Module.singleton_class.prepend(CallableInvocationGuard)
    private_constant :CallableInvocationGuard
  end
end
