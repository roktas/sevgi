# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # DSL helpers for defining one SVG template and repeating it through `use` elements.
      #
      # Use {Sevgi::Sundries::Tile} instead when Ruby code needs inspectable repeated geometry or row/column bounds
      # rather than SVG references.
      # @see Sevgi::Sundries::Tile
      # @see https://sevgi.roktas.dev/sundries/#choose-a-layout-model Choosing a layout model
      module Tile
        # Stable prefix used for generated tile CSS classes.
        PREFIX = "tile"

        # Builds a two-dimensional tile grid.
        # Each use id has the form `id-row-column`, with one-based row and column numbers. Generated classes identify
        # the one-based row and column and mark their first and last positions. A block defines the referenced template
        # as a group under `defs` before the uses are added.
        # @example Define and customize a tile grid
        #   customize = proc { |use, x:, y:, nx:, ny:| use[:opacity] = (x + y + 1).fdiv(nx + ny) }
        #   Sevgi::Graphics.SVG(:minimal) do
        #     Tile("dot", nx: 2, dx: 10, ny: 2, dy: 10, proc: customize) { circle r: 2 }
        #   end
        # @param id [String] referenced template id
        # @param nx [Integer] number of columns
        # @param dx [Numeric] finite horizontal spacing, normalized before coordinates are rendered
        # @param ox [Numeric] finite horizontal offset, normalized before coordinates are rendered
        # @param ny [Integer] number of rows
        # @param dy [Numeric] finite vertical spacing, normalized before coordinates are rendered
        # @param oy [Numeric] finite vertical offset, normalized before coordinates are rendered
        # @param proc [Proc, nil] optional callback invoked for each use as `(element, x:, y:, nx:, ny:)`, with
        #   zero-based coordinates and total counts; the callback may mutate the element and its return value is ignored
        # @yield evaluates the template drawing DSL in a generated `defs` group named by id
        # @yieldreturn [Object] ignored block result
        # @return [Sevgi::Graphics::Element] self
        # @raise [Sevgi::ArgumentError] when a required tile argument is missing or invalid
        def Tile(
          id = Undefined,
          nx: Undefined,
          dx: Undefined,
          ox: 0,
          ny: Undefined,
          dy: Undefined,
          oy: 0,
          proc: nil,
          &block
        )
          id, nx, dx, ox, ny, dy, oy, callback = Helper
            .normalize(id:, nx:, dx:, ox:, ny:, dy:, oy:, proc:)
            .values_at(:id, :nx, :dx, :ox, :ny, :dy, :oy, :proc)

          defs { g(id:, &block) } if block

          Within do
            ny.times do |y|
              rs = Helper.classify(as: "row", index: y, upper: ny)

              nx.times do |x|
                cs = Helper.classify(as: "col", index: x, upper: nx)

                element = use(
                  id: [id, y + 1, x + 1].join("-"),
                  href: "##{id}",
                  class: [*rs, *cs].join(" "),
                  **Helper.coordinates(
                    x: Scalar.number((x * dx) + ox, context: "tile", field: :x),
                    y: Scalar.number((y * dy) + oy, context: "tile", field: :y)
                  )
                )
                callback&.call(element, x:, y:, nx:, ny:)
              end
            end
          end
        end

        # Builds a one-dimensional horizontal tile row.
        # Each use id has the form `id-column`, with a one-based column number. Generated classes identify the column and
        # mark its first and last positions. A block defines the referenced template as a group under `defs` before the
        # uses are added.
        # @param id [String] referenced template id
        # @param n [Integer] number of instances
        # @param d [Numeric] finite horizontal spacing, normalized before coordinates are rendered
        # @param o [Numeric] finite horizontal offset, normalized before coordinates are rendered
        # @param proc [Proc, nil] optional callback invoked for each use as `(element, x:, n:)`, with a zero-based column
        #   and total count; the callback may mutate the element and its return value is ignored
        # @yield evaluates the template drawing DSL in a generated `defs` group named by id
        # @yieldreturn [Object] ignored block result
        # @return [Sevgi::Graphics::Element] self
        # @raise [Sevgi::ArgumentError] when a required tile argument is missing or invalid
        def TileX(id = Undefined, n: Undefined, d: Undefined, o: 0, proc: nil, &block)
          id, n, d, o, callback = Helper.normalize(id:, n:, d:, o:, proc:).values_at(:id, :n, :d, :o, :proc)

          defs { g(id:, &block) } if block

          Within do
            n.times do |x|
              cs = Helper.classify(as: "col", index: x, upper: n)

              element = use(
                id: [id, x + 1].join("-"),
                href: "##{id}",
                class: cs.join(" "),
                **Helper.coordinates(x: Scalar.number((x * d) + o, context: "tile", field: :x))
              )
              callback&.call(element, x:, n:)
            end
          end
        end

        # Builds a one-dimensional vertical tile column.
        # Each use id has the form `id-row`, with a one-based row number. Generated classes identify the row and mark its
        # first and last positions. A block defines the referenced template as a group under `defs` before the uses are
        # added.
        # @param id [String] referenced template id
        # @param n [Integer] number of instances
        # @param d [Numeric] finite vertical spacing, normalized before coordinates are rendered
        # @param o [Numeric] finite vertical offset, normalized before coordinates are rendered
        # @param proc [Proc, nil] optional callback invoked for each use as `(element, y:, n:)`, with a zero-based row and
        #   total count; the callback may mutate the element and its return value is ignored
        # @yield evaluates the template drawing DSL in a generated `defs` group named by id
        # @yieldreturn [Object] ignored block result
        # @return [Sevgi::Graphics::Element] self
        # @raise [Sevgi::ArgumentError] when a required tile argument is missing or invalid
        def TileY(id = Undefined, n: Undefined, d: Undefined, o: 0, proc: nil, &block)
          id, n, d, o, callback = Helper.normalize(id:, n:, d:, o:, proc:).values_at(:id, :n, :d, :o, :proc)

          defs { g(id:, &block) } if block

          Within do
            n.times do |y|
              rs = Helper.classify(as: "row", index: y, upper: n)

              element = use(
                id: [id, y + 1].join("-"),
                href: "##{id}",
                class: rs.join(" "),
                **Helper.coordinates(y: Scalar.number((y * d) + o, context: "tile", field: :y))
              )
              callback&.call(element, y:, n:)
            end
          end
        end

        # Tile argument validation and class helpers.
        # @api private
        module Helper
          extend self

          FINITE = %i[d dx dy o ox oy].freeze

          # Argument validators for tile helpers.
          ASSERTION = {
            id: proc { |name, value| "Argument '#{name}' must be a string" unless value.is_a?(::String) },
            n: proc { |name, value| positive_integer_issue(name, value) },
            nx: proc { |name, value| positive_integer_issue(name, value) },
            ny: proc { |name, value| positive_integer_issue(name, value) },
            proc: proc { |name, value| "Argument '#{name}' must be a proc" unless value.nil? || value.is_a?(::Proc) }
          }.freeze

          # Returns a validation issue unless value is a positive integer.
          # @param name [Symbol] argument name
          # @param value [Object] argument value
          # @return [String, nil] validation issue
          def positive_integer_issue(name, value)
            "Argument '#{name}' must be a positive integer" unless value.is_a?(::Integer) && value.positive?
          end

          # Validates and normalizes tile arguments.
          # @param kwargs [Hash] tile arguments
          # @return [Hash] independent arguments with spacing and offsets normalized to SVG numbers
          # @raise [Sevgi::ArgumentError] when an argument is missing or invalid
          def normalize(**kwargs)
            kwargs.to_h do |name, value|
              ArgumentError.("Argument '#{name}' required") if value == Undefined
              [name, normalize_value(name, value)]
            end
          end

          def coordinates(**coordinates)
            coordinates.reject { |_, value| value.zero? }
          end

          def normalize_value(name, value)
            return number(name, value) if FINITE.include?(name)
            return value unless (assertion = ASSERTION[name])
            return value unless (issue = assertion.call(name, value))

            ArgumentError.(issue)
          end

          def number(name, value)
            Scalar.number(value, context: "tile", field: name)
          rescue ::Sevgi::ArgumentError
            ArgumentError.("Argument '#{name}' must be a finite real number")
          end

          # Returns positional tile CSS classes.
          # @param as [String] class axis label
          # @param index [Integer] zero-based index
          # @param upper [Integer] item count
          # @return [Array<String>]
          def classify(as:, index:, upper:)
            [].tap do |classes|
              classes << "#{PREFIX}-#{as}-#{index + 1}"
              classes << "#{PREFIX}-#{as}-first" if index.zero?
              classes << "#{PREFIX}-#{as}-last" if index + 1 == upper
            end
          end

          private :normalize_value, :number
        end

        private_constant :Helper
      end
    end
  end
end
