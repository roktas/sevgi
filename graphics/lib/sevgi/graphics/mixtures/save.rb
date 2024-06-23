# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Save
        EXT = ".svg"

        def Out(*, **)                 = F.out(self.(**), *)

        def Out!(*, **, &filter)       = F.out(self.(**), *, update: true, &filter)

        def Save(*paths, **)           = Out(F.touch(*(paths.empty? ? caller_locations(1..1).first.path : paths), ext: EXT), **)

        def Save!(*paths, **, &filter) = Out!(F.touch(*(paths.empty? ? caller_locations(1..1).first.path : paths), ext: EXT), **, &filter)
      end
    end
  end
end
