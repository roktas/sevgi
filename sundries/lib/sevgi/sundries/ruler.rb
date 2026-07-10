# frozen_string_literal: true

module Sevgi
  module Sundries
    # A one-dimensional interval divided into equal units.
    #
    # The compact reader names are part of the domain vocabulary:
    # `u` is the unit length, `n` is the interval count, `d` is total
    # distance, and `h` is the midpoint distance.
    #
    # @example Interval geometry
    #   # <---------------- d = n x u ---------------->
    #   # |---------+---------+---------+---------|
    #   #           <--- u --->
    #   interval = Sevgi::Sundries::Interval[3, 4]
    #   interval.d # => 12.0
    class Interval
      # Builds an interval using bracket syntax.
      # @param e [Numeric, #length] unit length or an object exposing length
      # @param n [Integer] non-negative interval count
      # @return [Sevgi::Sundries::Interval]
      # @raise [Sevgi::ArgumentError] when count is not a non-negative integer
      # @raise [Sevgi::ArgumentError] when the unit object does not expose length
      # @raise [Sevgi::ArgumentError] when the measured unit length is not numeric
      # @raise [Sevgi::ArgumentError] when the measured unit length is not finite
      # @raise [Sevgi::ArgumentError] when the measured unit length is not positive
      def self.[](e, n) = new(e, n)

      # @!attribute [r] n
      #   @return [Integer] interval count
      # @!attribute [r] u
      #   @return [Float] unit length
      attr_reader :n, :u

      # Creates an interval.
      # @param e [Numeric, #length] unit length or an object exposing length
      # @param n [Integer] non-negative interval count
      # @return [void]
      # @raise [Sevgi::ArgumentError] when count is not a non-negative integer
      # @raise [Sevgi::ArgumentError] when the unit object does not expose length
      # @raise [Sevgi::ArgumentError] when the measured unit length is not numeric
      # @raise [Sevgi::ArgumentError] when the measured unit length is not finite
      # @raise [Sevgi::ArgumentError] when the measured unit length is not positive
      def initialize(e, n)
        @n = non_negative_integer(n, "Interval count")
        @u = measure(e)
      end

      # Returns a major tick distance by index.
      # @param i [Integer] tick index
      # @return [Float, nil] distance from the interval origin, or nil when out of range
      def [](i) = ds[i]

      # Counts how many whole lengths fit into this interval.
      # @param length [Numeric] candidate length
      # @return [Integer]
      # @raise [Sevgi::ArgumentError] when length is not numeric
      # @raise [Sevgi::ArgumentError] when length is not finite
      # @raise [Sevgi::ArgumentError] when length is not positive
      def count(length) = (d / positive_number(length, "Interval count length")).to_i

      # Returns the total interval distance.
      # @return [Float]
      def d = @d ||= n * u

      # Returns major tick distances, including both endpoints.
      # @return [Array<Float>]
      def ds = @ds ||= Array.new(n + 1) { |i| i * u }

      # Returns the midpoint distance.
      # @return [Float]
      def h = @h ||= d / 2.0

      # Returns midpoint tick distances for each interval segment.
      # @return [Array<Float>]
      def hs = @hs ||= Array.new(n) { |i| u * (0.5 + i) }

      # Returns the last major tick index.
      # @return [Integer]
      def nds = @nds ||= ds.size - 1

      # Returns the last midpoint tick index.
      # @return [Integer]
      def nhs = @nhs ||= hs.size - 1

      # @return [Float] total interval distance
      alias length d

      private

      def measure(e)
        value = if e.is_a?(::Numeric)
          e
        else
          ArgumentError.("#{e.class}#length must be implemented") unless e.respond_to?(:length)

          e.length
        end

        positive_number(value, "Interval unit length")
      end

      def non_negative_integer(value, field)
        ArgumentError.("#{field} must be a non-negative Integer") unless value.is_a?(::Integer) && !value.negative?

        value
      end

      def non_negative_number(value, field)
        number = numeric(value, field)
        ArgumentError.("#{field} must be non-negative") if number.negative?

        number
      end

      def numeric(value, field)
        ArgumentError.("#{field} must be Numeric") unless value.is_a?(::Numeric)

        number = value.to_f
        ArgumentError.("#{field} must be finite") unless number.finite?

        number
      end

      def positive_integer(value, field)
        ArgumentError.("#{field} must be a positive Integer") unless value.is_a?(::Integer) && value.positive?

        value
      end

      def positive_number(value, field)
        number = numeric(value, field)
        ArgumentError.("#{field} must be positive") unless number.positive?

        number
      end
    end

    # Fits a repeated interval into a broader span with computed margins.
    #
    # A ruler stores both the fitted major interval and the source subinterval.
    # The compact reader names mirror {Interval}: `brut` is the full available
    # span, `sd/su/sn` describe the subinterval, and `waste` is distributed as
    # equal margins.
    #
    # @example Ruler geometry
    #   # <--------- d = n x sd ---------><--- waste = 2 x margin --->
    #   # <----- u = unit x multiple ----->
    #   # <---------------- brut ---------------->
    #   ruler = Sevgi::Sundries::Ruler.new(unit: 1, multiple: 10, brut: 150)
    #   ruler.d # => 150.0
    class Ruler < Interval
      # @!attribute [r] brut
      #   @return [Float] full available span before fitting
      # @!attribute [r] sub
      #   @return [Sevgi::Sundries::Interval] source subinterval
      attr_reader :brut, :sub

      # Creates a ruler fitted into the given span.
      # @param brut [Numeric] full available span
      # @param unit [Numeric] subinterval unit length
      # @param multiple [Integer] number of subinterval units per major interval
      # @param margin [Numeric] minimum margin on each side
      # @return [void]
      # @raise [Sevgi::ArgumentError] when brut is not numeric
      # @raise [Sevgi::ArgumentError] when brut is not finite
      # @raise [Sevgi::ArgumentError] when brut is negative
      # @raise [Sevgi::ArgumentError] when unit is not numeric
      # @raise [Sevgi::ArgumentError] when unit is not finite
      # @raise [Sevgi::ArgumentError] when unit is not positive
      # @raise [Sevgi::ArgumentError] when multiple is not a positive integer
      # @raise [Sevgi::ArgumentError] when margin is not numeric
      # @raise [Sevgi::ArgumentError] when margin is not finite
      # @raise [Sevgi::ArgumentError] when margin is negative
      # @raise [Sevgi::ArgumentError] when the fitting span is negative
      def initialize(brut:, unit:, multiple:, margin: 0.0)
        @brut = non_negative_number(brut, "Ruler brut")
        unit = positive_number(unit, "Ruler unit")
        multiple = positive_integer(multiple, "Ruler multiple")
        margin = non_negative_number(margin, "Ruler margin")
        @sub = Interval.new(unit, multiple)

        n = divide(unit:, multiple:, brut: @brut, margin:)

        ArgumentError.("Ruler fitting span must not be negative") if n.negative?

        super(@sub, n)
      end

      # Returns a ruler where the source subinterval is flattened into units.
      # @return [Sevgi::Sundries::Ruler]
      def expand = self.class.new(unit: sub.u, multiple: 1, brut: d + waste, margin:)

      # Returns the computed margin after fitting.
      # @return [Float]
      def margin = @margin ||= waste / 2.0

      # Returns minor tick distances across the fitted span.
      # @return [Array<Float>]
      def ms = @ms ||= expand.ds

      # Returns the unfitted distance distributed outside the fitted span.
      # @return [Float]
      def waste = @waste ||= brut - d

      # Returns the source subinterval count.
      # @return [Integer]
      def sn = @sub.n

      # Returns the source subinterval distance.
      # @return [Float]
      def sd = @sub.d

      # Returns the source subinterval unit length.
      # @return [Float]
      def su = @sub.u

      protected

      # Computes the number of major intervals fitting in the available span.
      # @param unit [Numeric] subinterval unit length
      # @param multiple [Integer] number of subinterval units per major interval
      # @param brut [Numeric] full available span
      # @param margin [Numeric] minimum margin on each side
      # @return [Integer]
      def divide(unit:, multiple:, brut:, margin:) = F.count(brut - (2 * margin), unit * multiple)
    end

    # Ruler variant that always chooses an even number of major intervals.
    class RulerEven < Ruler
      protected

      # Computes an even number of major intervals fitting in the available span.
      # @return [Integer]
      def divide(...) = (n = super).even? ? n : (n - 1)
    end
  end
end
