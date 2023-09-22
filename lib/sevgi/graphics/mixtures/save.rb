# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Save
        module InstanceMethods
          EXT = ".svg"

          def Out(*, **)                = F.out(self.(**), *)

          def Out!(*, **)               = F.out(self.(**), *, smart: true)

          def Save(dir = ".", **)       = Out(Savefile(caller_locations(1..1).first.path, dir), **)

          def Save!(dir = ".", **)      = Out!(Savefile(caller_locations(1..1).first.path, dir), **)

          def Savefile(path, dir = ".") = ::File.expand_path(::File.join(dir, "#{::File.basename(path, ".*")}#{EXT}"), ::File.dirname(path))
        end
      end
    end
  end
end
