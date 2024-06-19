# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Identify
        class Identifiers
          attr_reader :element, :namespace, :collision

          def initialize(element)
            @element   = element
            @namespace = {}
            @collision = {}

            build
          end

          def conflict?
            !@collision.empty?
          end

          def [](*)
            @namespace[*]
          end

          private

            def build
              element.Traverse do |element|
                next unless (id = element[:id])

                if @namespace.key?(id)
                  (@collision[id] ||= [ @namespace[id] ]) << element
                else
                  @namespace[id] = element
                end
              end
            end
        end

        def Disidentify
          Traverse do |element|
            next unless element[:id]

            element[:_id] = element.attributes.delete(:id)
          end
        end

        def IdentifyAsTable(...) = IdentifyAsTable.(...)

        def IdentifyAsList(...)  = IdentifyAsList.(...)

        def Reidentify
        end

        def Identifiers = Identifiers.new(self)

        SEPARATOR = "-"

        IdentifyAs = Data.define(:id) do
          def label(*indexes)
            id and [ id, *indexes ].map(&:to_s).join(SEPARATOR)
          end
        end

        IdentifyAsList = Class.new(IdentifyAs) do
          def self.call(element, i)
            element.each_with_index do |it, index|
              i and (label = self[i].label(index + 1)) and it[:id] = label
            end
          end
        end

        IdentifyAsTable = Class.new(IdentifyAs) do
          def self.call(element, ix: nil, iy: nil)
            element.each_with_index do |row, irow|
              iy and (label = self[iy].label(irow + 1)) and row[:id] = label
              ix and row.children.each_with_index do |col, icol|
                (label = self[ix].label(irow + 1, icol + 1)) and col[:id] = label
              end
            end
          end
        end

        private_constant :IdentifyAs, :IdentifyAsTable, :IdentifyAsList
      end
    end
  end
end
