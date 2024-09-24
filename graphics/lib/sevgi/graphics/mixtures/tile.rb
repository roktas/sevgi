# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Tile
        PROC = proc do |element, href, *positions|
          element[:id] = [ href, *positions.compact ].join("-")
        end

        # rubocop:disable Layout/MultilineArrayLineBreaks,Metrics/MethodLength

        def Tile(id = Undefined, nx: Undefined, dx: Undefined, ox: 0, ny: Undefined, dy: Undefined, oy: 0, &block)
          Assert.(id:, nx:, dx:, ox:, ny:, dy:, oy:)

          href, coords = id, proc do |x, y|
            x.zero? ? (y.zero? ? {} : { y: }) : (y.zero? ? { x: } : { x:, y: }) # for pretty kwargs handling
          end

          defs { g(id:, &block) } if block

          Within do
            ny.times do |i|
              nx.times do |j|
                PROC.(use(href: "##{href}", **coords.(j * dx + ox, i * dy + oy)), href, i + 1, j + 1)
              end
            end
          end
        end

        def TileX(id = Undefined, n: Undefined, d: Undefined, o: 0, &block)
          Assert.(id:, n:, d:, o:)

          href, coords = id, proc do |x|
            x.zero? ? {} : { x: } # for pretty kwargs handling
          end

          defs { g(id:, &block) } if block

          Within do
            n.times do |i|
              PROC.(use(href: "##{href}", **coords.(i * d + o)), href, i + 1)
            end
          end
        end

        def TileY(id = Undefined, n: Undefined, d: Undefined, o: 0, &block)
          Assert.(id:, n:, d:, o:)

          href, coords = id, proc do |y|
            y.zero? ? {} : { y: } # for pretty kwargs handling
          end

          defs { g(id:, &block) } if block

          Within do
            n.times do |i|
              PROC.(use(href: "##{href}", **coords.(i * d + o)), href, i + 1)
            end
          end
        end

        module Assert
          extend self

          ASSERTION = {
            id: proc { |name, value| "Argument '#{name}' must be a string"           unless value.is_a?(::String)  },
            n:  proc { |name, value| "Argument '#{name}' must be a positive integer" unless value.positive?        },
            nx: proc { |name, value| "Argument '#{name}' must be a positive integer" unless value.positive?        },
            ny: proc { |name, value| "Argument '#{name}' must be a positive integer" unless value.positive?        },
            d:  proc { |name, value| "Argument '#{name}' must be a number"           unless value.is_a?(::Numeric) },
            dx: proc { |name, value| "Argument '#{name}' must be a number"           unless value.is_a?(::Numeric) },
            dy: proc { |name, value| "Argument '#{name}' must be a number"           unless value.is_a?(::Numeric) },
            o:  proc { |name, value| "Argument '#{name}' must be a number"           unless value.is_a?(::Numeric) },
            ox: proc { |name, value| "Argument '#{name}' must be a number"           unless value.is_a?(::Numeric) },
            oy: proc { |name, value| "Argument '#{name}' must be a number"           unless value.is_a?(::Numeric) }
          }.freeze

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

        private_constant :Assert
      end
    end
  end
end
