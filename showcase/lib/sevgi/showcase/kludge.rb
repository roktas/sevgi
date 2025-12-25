# frozen_string_literal: true

module Sevgi
  module Graphics
    module Document
      class Base
        def Save(*, **) = Out(**)
        def Save!(...)  = Save(...)
      end
    end
  end
end
