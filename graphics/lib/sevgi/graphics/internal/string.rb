# frozen_string_literal: true

module Sevgi
  module Function
    module String
      def demodulize(path)
        path = path.to_s
        if i = path.rindex("::")
          path[(i + 2), path.length]
        else
          path
        end
      end
    end

    extend String
  end
end
