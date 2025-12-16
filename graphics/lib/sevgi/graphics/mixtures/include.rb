# frozen_string_literal: true

require "sevgi/derender"

module Sevgi
  module Graphics
    module Mixtures
      module Include
        def Include(file, id)  = Derender.evaluate_file(file, self, id:)

        def Include!(file, id) = Derender.evaluate_file!(file, self, id:)
      end
    end
  end
end
