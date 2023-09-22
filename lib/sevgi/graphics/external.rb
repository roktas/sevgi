# frozen_string_literal: true

module Sevgi
  module Graphics
    module External
      def Canvas(...)                                        = Canvas.(...)

      def Verbatim(content)                                  = Content::Verbatim.new(content)

      def SVG(document = :default, canvas = nil, **, &block) = Profile.(document, canvas, **, &block)
    end

    extend External
  end
end
