# frozen_string_literal: true

require "sevgi/sundries/printer"

module Sevgi
  module Graphics
    module Mixtures
      module Print
        EXT = ".svg"

        def Print(path = nil, verbose: false, simulate: false, backup_suffix: nil, &filter)
          Save(path, default: F.subext(EXT, caller_locations(1..1).first.path), backup_suffix:, &filter)
          Sundries::Printer.(path, verbose:, simulate:)
        end
      end
    end
  end
end
