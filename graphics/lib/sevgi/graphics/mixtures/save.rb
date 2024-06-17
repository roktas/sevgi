# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Save
        EXT = ".svg"

        def Out(*, **)        = F.out(self.(**), *)

        def Out!(*, **)       = F.out(self.(**), *, update: true)

        def Save(*paths, **)  = Out(F.touch(*(paths.empty? ? caller_locations(1..1).first.path : paths), ext: EXT), **)

        def Save!(*paths, **) = Out!(F.touch(*(paths.empty? ? caller_locations(1..1).first.path : paths), ext: EXT), **)
      end
    end
  end
end
