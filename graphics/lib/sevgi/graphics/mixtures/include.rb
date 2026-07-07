# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Include
        require "sevgi/derender"

        def Include(file, id) = Derender.evaluate_file(file, self, id:)
        def IncludeChildren(file, id) = Derender.evaluate_file!(file, self, id:)
      rescue ::LoadError => e
        raise unless e.path == "sevgi/derender"

        def IncludeChildren(...) = MissingComponentError.("sevgi/derender")
        def Include(...) = MissingComponentError.("sevgi/derender")
      end
    end
  end
end
