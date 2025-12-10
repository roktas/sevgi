# frozen_string_literal: true

module Sevgi
  module Graphics
    module Document
      class Base < Proto
        document :base

        mixture :Call
        mixture :Duplicate
        mixture :Identify
        mixture :Lint
        mixture :Save
        mixture :Tile
        mixture :Transform
        mixture :Underscore
        mixture :Validate

        mixture :Hatch
        mixture :Include
        mixture :Print
        mixture :Symbols

        def PreRender(**options)
          self.Validate if options[:validate]
          self.Lint     if options[:lint]
        end
      end
    end
  end
end
