# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # rubocop:disable Metrics/MethodLength
      # DSL helpers for repeated SVG use elements.
      module Tile
        # Prefix used for generated tile CSS classes.
        PREFIX = "tile"

        # Builds a two-dimensional tile grid.
        # @param id [String] referenced template id
        # @param nx [Integer] number of columns
        # @param dx [Numeric] horizontal spacing
        # @param ox [Numeric] horizontal offset
        # @param ny [Integer] number of rows
        # @param dy [Numeric] vertical spacing
        # @param oy [Numeric] vertical offset
        # @param proc [Proc, nil] optional coordinate/customization proc
        # @yield evaluates the template drawing DSL in a generated group
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
          Helper.assert(id:, nx:, dx:, ox:, ny:, dy:, oy:, proc:)

          href, coords = id, proc do |x, y|
            # rubocop:disable Style/NestedTernaryOperator
            # for pretty kwargs handling
            x.zero? ? (y.zero? ? {} : {y:}) : (y.zero? ? {x:} : {x:, y:})
            # rubocop:enable Style/NestedTernaryOperator
          end

          defs { g(id:, &block) } if block

          Within do
            ny.times do |y|
              rs = Helper.classify(as: "row", index: y, upper: ny)

              nx.times do |x|
                cs = Helper.classify(as: "col", index: x, upper: nx)

                element = use(
                  id: [href, y + 1, x + 1].join("-"),
                  href: "##{href}",
                  class: [*rs, *cs].join(" "),
                  **coords.((x * dx) + ox, (y * dy) + oy)
                )
                proc&.call(element, x:, y:, nx:, ny:)
              end
            end
          end
        end

        # Builds a one-dimensional horizontal tile row.
        # @param id [String] referenced template id
        # @param n [Integer] number of instances
        # @param d [Numeric] horizontal spacing
        # @param o [Numeric] horizontal offset
        # @param proc [Proc, nil] optional coordinate/customization proc
        # @yield evaluates the template drawing DSL in a generated group
        # @yieldreturn [Object] ignored block result
        # @return [Sevgi::Graphics::Element] self
        # @raise [Sevgi::ArgumentError] when a required tile argument is missing or invalid
        def TileX(id = Undefined, n: Undefined, d: Undefined, o: 0, proc: nil, &block)
          Helper.assert(id:, n:, d:, o:, proc:)

          href, coords = id, proc do |x|
            # for pretty kwargs handling
            x.zero? ? {} : {x:}
          end

          defs { g(id:, &block) } if block

          Within do
            n.times do |x|
              cs = Helper.classify(as: "col", index: x, upper: n)

              element = use(
                id: [href, x + 1].join("-"),
                href: "##{href}",
                class: cs.join(" "),
                **coords.((x * d) + o)
              )
              proc&.call(element, x:, n:)
            end
          end
        end

        # Builds a one-dimensional vertical tile column.
        # @param id [String] referenced template id
        # @param n [Integer] number of instances
        # @param d [Numeric] vertical spacing
        # @param o [Numeric] vertical offset
        # @param proc [Proc, nil] optional coordinate/customization proc
        # @yield evaluates the template drawing DSL in a generated group
        # @yieldreturn [Object] ignored block result
        # @return [Sevgi::Graphics::Element] self
        # @raise [Sevgi::ArgumentError] when a required tile argument is missing or invalid
        def TileY(id = Undefined, n: Undefined, d: Undefined, o: 0, proc: nil, &block)
          Helper.assert(id:, n:, d:, o:, proc:)

          href, coords = id, proc do |y|
            # for pretty kwargs handling
            y.zero? ? {} : {y:}
          end

          defs { g(id:, &block) } if block

          Within do
            n.times do |y|
              rs = Helper.classify(as: "row", index: y, upper: n)

              element = use(
                id: [href, y + 1].join("-"),
                href: "##{href}",
                class: rs.join(" "),
                **coords.((y * d) + o)
              )
              proc&.call(element, y:, n:)
            end
          end
        end

        # Tile argument validation and class helpers.
        # @api private
        module Helper
          extend self

          # Argument validators for tile helpers.
          ASSERTION = {
            id: proc { |name, value| "Argument '#{name}' must be a string" unless value.is_a?(::String) },
            n: proc { |name, value| positive_integer_issue(name, value) },
            nx: proc { |name, value| positive_integer_issue(name, value) },
            ny: proc { |name, value| positive_integer_issue(name, value) },
            d: proc { |name, value| "Argument '#{name}' must be a number" unless value.is_a?(::Numeric) },
            dx: proc { |name, value| "Argument '#{name}' must be a number" unless value.is_a?(::Numeric) },
            dy: proc { |name, value| "Argument '#{name}' must be a number" unless value.is_a?(::Numeric) },
            o: proc { |name, value| "Argument '#{name}' must be a number" unless value.is_a?(::Numeric) },
            ox: proc { |name, value| "Argument '#{name}' must be a number" unless value.is_a?(::Numeric) },
            oy: proc { |name, value| "Argument '#{name}' must be a number" unless value.is_a?(::Numeric) },
            proc: proc { |name, value| "Argument '#{name}' must be a proc" unless value.nil? || value.is_a?(::Proc) }
          }.freeze

          # Returns a validation issue unless value is a positive integer.
          # @param name [Symbol] argument name
          # @param value [Object] argument value
          # @return [String, nil] validation issue
          def positive_integer_issue(name, value)
            "Argument '#{name}' must be a positive integer" unless value.is_a?(::Integer) && value.positive?
          end

          # Validates tile arguments.
          # @param kwargs [Hash] tile arguments
          # @return [nil]
          # @raise [Sevgi::ArgumentError] when an argument is missing or invalid
          def assert(**kwargs)
            kwargs.each do |name, value|
              issue = "Argument '#{name}' required" if value == Undefined

              unless issue
                next unless (assertion = ASSERTION[name])
                next unless (issue = assertion.call(name, value))
              end

              ArgumentError.(issue)
            end
            # rubocop:enable Metrics/MethodLength
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
        end

        private_constant :Helper
      end
    end
  end
end
