# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Save
        EXT = ".svg"

        def Out(*, **, &filter)
          F.out(self.(**), *, update: true, &filter)
        end

        def Save(path = nil, default: nil, &filter)
          default ||= F.subext(EXT, caller_locations(1..1).first.path)

          if path
            ::File.directory?(path) ? ::File.join(path, ::File.basename(default)) : path
          else
            default
          end => path

          Out(F.touch(path), &filter)
        end
      end
    end
  end
end
