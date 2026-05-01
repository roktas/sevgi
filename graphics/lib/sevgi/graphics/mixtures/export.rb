# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Export
        require "sevgi/sundries"

        def PDF(path = nil, **kwargs, &block) = Export(path, **kwargs, format: :pdf, &block)
        def PNG(path = nil, **kwargs, &block) = Export(path, **kwargs, format: :png, &block)

        private

          def Export(path = nil, default: nil, **kwargs, &block) # rubocop:disable Layout/IndentationConsistency
            default ||= F.subext(kwargs[:format] ? ".#{kwargs[:format]}" : ".pdf", caller_locations(2..2).first.path)

            if path
              ::File.directory?(path) ? ::File.join(path, ::File.basename(default)) : path
            else
              default
            end => path

            ::FileUtils.mkdir_p(::File.dirname(path))

            Sundries::Export.(self.call, path, **kwargs, &block)
          end
      rescue ::LoadError
        def PDF(...) = raise(NoMethodError, '"sevgi/sundries" required')
        def PNG(...) = raise(NoMethodError, '"sevgi/sundries" required')
      end
    end
  end
end
