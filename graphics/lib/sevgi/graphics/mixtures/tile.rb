# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Tile # rubocop:disable Layout/MultilineArrayLineBreaks,Metrics/MethodLength
        PREFIX = "tile"

        def Tile(id = Undefined, nx: Undefined, dx: Undefined, ox: 0, ny: Undefined, dy: Undefined, oy: 0, proc: nil, &block)
          Helper.assert(id:, nx:, dx:, ox:, ny:, dy:, oy:, proc:)

          href, coords = id, proc do |x, y|
            x.zero? ? (y.zero? ? {} : { y: }) : (y.zero? ? { x: } : { x:, y: }) # for pretty kwargs handling
          end

          defs { g(id:, &block) } if block

          Within do
            ny.times do |y|
              rs = Helper.classify(as: "row", index: y, upper: ny)

              nx.times do |x|
                cs = Helper.classify(as: "col", index: x, upper: nx)

                element = use(
                  id:    [ href, y + 1, x + 1 ].join("-"),
                  href:  "##{href}",
                  class: [ *rs, *cs ].join(" "),
                  **coords.(x * dx + ox, y * dy + oy)
                )
                proc.call(element, x:, y:, nx:, ny:) if proc
              end
            end
          end
        end

        def Tile!(id, klass = PREFIX, ...) =  g(id:, class: klass) { Tile(id, ...) }

        def TileX(id = Undefined, n: Undefined, d: Undefined, o: 0, proc: nil, &block)
          Helper.assert(id:, n:, d:, o:, proc:)

          href, coords = id, proc do |x|
            x.zero? ? {} : { x: } # for pretty kwargs handling
          end

          defs { g(id:, &block) } if block

          Within do
            n.times do |x|
              cs = Helper.classify(as: "col", index: x, upper: n)

              element = use(
                id:    [ href, x + 1 ].join("-"),
                href:  "##{href}",
                class: cs.join(" "),
                **coords.(x * d + o)
              )
              proc.call(element, x:, n:) if proc
            end
          end
        end

        def TileX!(id, klass = PREFIX, ...) =  g(id:, class: klass) { TileX(id, ...) }

        def TileY(id = Undefined, n: Undefined, d: Undefined, o: 0, proc: nil, &block)
          Helper.assert(id:, n:, d:, o:, proc:)

          href, coords = id, proc do |y|
            y.zero? ? {} : { y: } # for pretty kwargs handling
          end

          defs { g(id:, &block) } if block

          Within do
            n.times do |y|
              rs = Helper.classify(as: "row", index: y, upper: n)

              element = use(
                id:    [ href, y + 1 ].join("-"),
                href:  "##{href}",
                class: rs.join(" "),
                **coords.(y * d + o)
              )
              proc.call(element, y:, n:) if proc
            end
          end
        end

        def TileY!(id, klass = PREFIX, ...) =  g(id:, class: klass) { TileY(id, ...) }

        module Helper
          extend self

          ASSERTION = {
            id:   proc { |name, value| "Argument '#{name}' must be a string"           unless value.is_a?(::String)             },
            n:    proc { |name, value| "Argument '#{name}' must be a positive integer" unless value.positive?                   },
            nx:   proc { |name, value| "Argument '#{name}' must be a positive integer" unless value.positive?                   },
            ny:   proc { |name, value| "Argument '#{name}' must be a positive integer" unless value.positive?                   },
            d:    proc { |name, value| "Argument '#{name}' must be a number"           unless value.is_a?(::Numeric)            },
            dx:   proc { |name, value| "Argument '#{name}' must be a number"           unless value.is_a?(::Numeric)            },
            dy:   proc { |name, value| "Argument '#{name}' must be a number"           unless value.is_a?(::Numeric)            },
            o:    proc { |name, value| "Argument '#{name}' must be a number"           unless value.is_a?(::Numeric)            },
            ox:   proc { |name, value| "Argument '#{name}' must be a number"           unless value.is_a?(::Numeric)            },
            oy:   proc { |name, value| "Argument '#{name}' must be a number"           unless value.is_a?(::Numeric)            },
            proc: proc { |name, value| "Argument '#{name}' must be a proc"             unless value.nil? || value.is_a?(::Proc) }
          }.freeze

          def assert(**kwargs)
            kwargs.each do |name, value|
              issue = "Argument '#{name}' required" if value == Undefined

              unless issue
                next unless (assertion = ASSERTION[name])
                next unless (issue = assertion.call(name, value))
              end

              ArgumentError.(issue)
            end
          end

          def classify(as:, index:, upper:)
            [].tap do |classes|
              classes << "#{PREFIX}-#{as}-#{index + 1}"
              classes << "#{PREFIX}-#{as}-first" if index.zero?
              classes << "#{PREFIX}-#{as}-last"  if index + 1 == upper
            end
          end
        end

        private_constant :Helper
      end
    end
  end
end
