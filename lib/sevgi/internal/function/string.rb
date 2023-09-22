# frozen_string_literal: true

module Sevgi
  module Function
    module String
      def start_with_upper?(string) = upper?(string[0])

      def upper?(char)              = /[[:upper:]]/.match?(char)
    end

    extend String
  end
end
