# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Save
        module InstanceMethods
          FILE_EXT   = ".svg"
          SEP_PREFIX = "_"
          SEP_SUFFIX = "-"

          def Out(*, **)
            F.out(self.(**), *)
          end

          def Out!(*, **)
            F.out(self.(**), *, update: true)
          end

          def Save(dir = ".", **)
            Out(Filepath(caller_locations(1..1).first.path, dir:), **)
          end

          def Save!(dir = ".", **)
            Out!(Filepath(caller_locations(1..1).first.path, dir:), **)
          end

          def SaveAs(path = nil, dir: ".", prefixes: nil, prefix_sep: SEP_PREFIX, suffixes: nil, suffix_sep: SEP_SUFFIX, ext: FILE_EXT)
            Out(Filepath(path || caller_locations(1..1).first.path, dir:, prefixes:, prefix_sep:, suffixes:, suffix_sep:, ext:))
          end

          def SaveAs!(path = nil, dir: ".", prefixes: nil, prefix_sep: SEP_PREFIX, suffixes: nil, suffix_sep: SEP_SUFFIX, ext: FILE_EXT)
            Out!(Filepath(path || caller_locations(1..1).first.path, dir:, prefixes:, prefix_sep:, suffixes:, suffix_sep:, ext:))
          end

          private

          def Filepath(path, dir: ".", prefixes: nil, prefix_sep: SEP_PREFIX, suffixes: nil, suffix_sep: SEP_SUFFIX, ext: FILE_EXT)
            filename = ::File.basename(path, ".*")

            filename = [ *prefixes, filename ].join(prefix_sep) if prefixes
            filename = [ filename, *suffixes ].join(suffix_sep) if suffixes

            filename = "#{filename}#{ext}"

            ::File.expand_path(::File.join(dir, filename), ::File.dirname(path))
          end
        end
      end
    end
  end
end
