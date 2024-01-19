# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Replicate
        module InstanceMethods
          # rubocop:disable Metrics/MethodLength
          def Replicate(nx: Undefined, dx: Undefined, ix: nil, ny: Undefined, dy: Undefined, iy: nil, id: nil, &block)
            Ensure.without_block(block, nx:, dx:, ny:, dy:)

            With do |base|
              layer(id:) do
                row = layer do
                  (nx - 1).times do |time|
                    base.DuplicateH((time + 1) * dx, parent: self)
                  end
                end

                base.AdoptFirst(row)

                (ny - 1).times do |time|
                  row.DuplicateV((time + 1) * dy)
                end
              end.tap do |element|
                IdentifyAsTable(element.children, ix:, iy:)
              end
            end
          end

          def ReplicateH(n: Undefined, d: Undefined, i: nil, id: nil, &block)
            Ensure.without_block(block, n:, d:)

            With do |base|
              layer(id:) do
                (n - 1).times { |time| base.DuplicateH((time + 1) * d, parent: self) }
              end.tap do |element|
                base.AdoptFirst(element)
                IdentifyAsList(element.children, i)
              end
            end
          end

          def ReplicateV(n: Undefined, d: Undefined, i: nil, id: nil, &block)
            Ensure.without_block(block, n:, d:)

            With do |base|
              layer(id:) do
                (n - 1).times { |time| base.DuplicateV((time + 1) * d, parent: self) }
              end.tap do |element|
                base.AdoptFirst(element)
                IdentifyAsList(element.children, i)
              end
            end
          end

          def Tile(symbol = Undefined, nx: Undefined, dx: Undefined, ix: nil, ny: Undefined, dy: Undefined, iy: nil, id: nil, &block)
            Ensure.with_block(block, symbol:, nx:, dx:, ny:, dy:)

            symbol(id: symbol).Within(&block)
            use("xlink:href": "##{symbol}").Replicate(nx:, dx:, ix:, ny:, dy:, iy:, id:)
          end

          def TileH(symbol = Undefined, n: Undefined, d: Undefined, i: nil, id: nil, &block)
            Ensure.with_block(block, symbol:, n:, d:)

            symbol(id: symbol).Within(&block)
            use("xlink:href": "##{symbol}").ReplicateH(n:, d:, i:, id:)
          end

          def TileV(symbol = Undefined, n: Undefined, d: Undefined, i: nil, id: nil, &block)
            Ensure.with_block(block, symbol:, n:, d:)

            symbol(id: symbol).Within(&block)
            use("xlink:href": "##{symbol}").ReplicateV(n:, d:, i:, id:)
          end
        end

        module Ensure
          extend self

          ASSERTION = {
            symbol: proc { |name, value| "Argument '#{name}' must be a string"           unless value.is_a?(::String)  },
            n:      proc { |name, value| "Argument '#{name}' must be a positive integer" unless value.positive?        },
            nx:     proc { |name, value| "Argument '#{name}' must be a positive integer" unless value.positive?        },
            ny:     proc { |name, value| "Argument '#{name}' must be a positive integer" unless value.positive?        },
            d:      proc { |name, value| "Argument '#{name}' must be a number"           unless value.is_a?(::Numeric) },
            dx:     proc { |name, value| "Argument '#{name}' must be a number"           unless value.is_a?(::Numeric) },
            dy:     proc { |name, value| "Argument '#{name}' must be a number"           unless value.is_a?(::Numeric) }
          }.freeze

          def with_block(block, **)
            ArgumentError.("Block required") unless block

            call(**)
          end

          def without_block(block, **)
            ArgumentError.("Block not allowed") if block

            call(**)
          end

          private

          def call(**kwargs)
            kwargs.each do |name, value|
              issue = "Argument '#{name}' required" if value == Undefined

              unless issue
                next unless (assertion = ASSERTION[name])
                next unless (issue = assertion.call(name, value))
              end

              ArgumentError.(issue)
            end
          end
        end
      end
    end
  end
end
