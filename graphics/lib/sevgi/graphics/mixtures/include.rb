# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Include
        require "sevgi/derender"

        def Include(file, id)  = Derender.evaluate_file(file, self, id:)
        def Include!(file, id) = Derender.evaluate_file!(file, self, id:)
      rescue ::LoadError
        def Include(...)       = raise(NoMethodError, '"sevgi/derender" required')
        def Include!(...)      = raise(NoMethodError, '"sevgi/derender" required')
      end
    end
  end
end
