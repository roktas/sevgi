# frozen_string_literal: true

require "sevgi/derender"

module Sevgi
  module Graphics
    module Mixtures
      module Include
        def Include(file, id)
          Derender.(file, id).(self)
        end
      end
    end
  end
end
