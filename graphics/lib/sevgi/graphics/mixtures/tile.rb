# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Tile
        DEFAULT_PROC = proc do |element, href, *positions|
          element[:id] = [ href, *positions.compact ].join("-")
        end

        # rubocop:disable Layout/MultilineArrayLineBreaks,Metrics/MethodLength

        def Tile(id = nil, nx: Undefined, dx: Undefined, ox: 0, ny: Undefined, dy: Undefined, oy: 0, &block)
          Assert.(tiled = id || self[:id], nx:, dx:, ox:, ny:, dy:, oy:)

          href, proc, coords = tiled, block || DEFAULT_PROC, proc do |x, y|
            x.zero? ? (y.zero? ? {} : { y: }) : (y.zero? ? { x: } : { x:, y: }) # for pretty kwargs handling
          end

          public_send(id.nil? ? :With : :Within) do
            ny.times do |i|
              nx.times do |j|
                proc.(use(href: "##{href}", **coords.(j * dx + ox, i * dy + oy)), href, i + 1, j + 1)
              end
            end
          end
        end

        def TileX(id = nil, n: Undefined, d: Undefined, o: 0, &block)
          Assert.(tiled = id || self[:id], n:, d:, o:)

          href, proc, coords = tiled, block || DEFAULT_PROC, proc do |x|
            x.zero? ? {} : { x: } # for pretty kwargs handling
          end

          public_send(id.nil? ? :With : :Within) do
            n.times do |i|
              proc.(use(href: "##{href}", **coords.(i * d + o)), href, i + 1)
            end
          end
        end

        def TileY(id = nil, n: Undefined, d: Undefined, o: 0, &block)
          Assert.(tiled = id ||self[:id], n:, d:, o:)

          href, proc, coords = tiled, block || DEFAULT_PROC, proc do |y|
            y.zero? ? {} : { y: } # for pretty kwargs handling
          end

          public_send(id.nil? ? :With : :Within) do
            n.times do |i|
              proc.(use(href: "##{href}", **coords.(i * d + o)), href, i + 1)
            end
          end
        end
      end

      module Assert
        extend self

        ASSERTION = {
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

        def call(id, **kwargs)
          ArgumentError.("Tiled element must have an id") unless id

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
