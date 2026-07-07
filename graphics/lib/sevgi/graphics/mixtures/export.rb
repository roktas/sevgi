# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Export
        def PDF(path = nil, **kwargs, &block)
          begin
            require "sevgi/sundries"

          rescue ::LoadError => e
            raise unless e.path == "sevgi/sundries"

            MissingComponentError.("sevgi/sundries")
          end

          Export(path, **kwargs, format: :pdf, &block)
        end

        def PNG(path = nil, **kwargs, &block)
          begin
            require "sevgi/sundries"

          rescue ::LoadError => e
            raise unless e.path == "sevgi/sundries"

            MissingComponentError.("sevgi/sundries")
          end

          Export(path, **kwargs, format: :png, &block)
        end

        private

        def Export(path = nil, default: nil, **kwargs, &block)
          default ||= F.subext(kwargs[:format] ? ".#{kwargs[:format]}" : ".pdf", caller_locations(2..2).first.path)

          if path
            ::File.directory?(path) ? ::File.join(path, ::File.basename(default)) : path
          else
            default
          end => path

          ::FileUtils.mkdir_p(::File.dirname(path))

          Sundries::Export.(call, path, **kwargs, &block)
        end
      end
    end
  end
end
