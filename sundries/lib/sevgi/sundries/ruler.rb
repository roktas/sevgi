# frozen_string_literal: true

module Sevgi
  module Sundries
    # A one-dimensional interval divided into equal units.
    #
    # The compact reader names are part of the domain vocabulary:
    # `u` is the unit length, `n` is the interval count, and `d` is total
    # distance. `ds` includes both endpoints, while `hs` contains one halfway
    # distance per interval. These compact names are intended to read as
    # formulas in layout code rather than as general-purpose collection names.
    #
    # @example Interval geometry
    #   # <---------------- d = n x u ---------------->
    #   # |---------+---------+---------+---------|
    #   #           <--- u --->
    #   interval = Sevgi::Sundries::Interval[3, 4]
    #   interval.d # => 12.0
    # @example Query major and halfway distances
    #   interval = Sevgi::Sundries::Interval[3, 4]
    #   interval.ds # => [0.0, 3.0, 6.0, 9.0, 12.0]
    #   interval.hs # => [1.5, 4.5, 7.5, 10.5]
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

      # Returns the interval count.
      # @return [Integer]
      attr_reader :n

      # Returns the unit length.
      # @return [Float]
      attr_reader :u

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
      # The memoized collection is frozen and must be treated as immutable.
      # @return [Array<Float>] frozen major tick distances
      def ds = @ds ||= Array.new(n + 1) { |i| i * u }.freeze

      # Returns the midpoint distance.
      # @return [Float]
      def h = @h ||= d / 2.0

      # Returns midpoint tick distances for each interval segment.
      # The memoized collection is frozen and must be treated as immutable.
      # @return [Array<Float>] frozen midpoint tick distances
      def hs = @hs ||= Array.new(n) { |i| u * (0.5 + i) }.freeze

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

        number = begin
          value.to_f
        rescue ::StandardError => e
          ArgumentError.("#{field} must be a finite Numeric: #{value.inspect} (#{e.message})")
        end

        ArgumentError.("#{field} must be a finite Numeric") unless number.is_a?(::Float)
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
    # `brut` is the full available span. `unit * multiple` becomes the major
    # interval, and `sd/su/sn` describe that source subinterval. Requested
    # margins are minimums: leftover space is split between them while their
    # start/end difference is preserved. The fitted `d` excludes those margins;
    # `waste` includes them and any remainder.
    #
    # @example Ruler geometry
    #   # <-- start --><--------- d = n x sd ---------><-- finish -->
    #   # <----- u = unit x multiple ----->
    #   # <---------------- brut ---------------->
    #   ruler = Sevgi::Sundries::Ruler.new(unit: 1, multiple: 10, brut: 150)
    #   ruler.d # => 150.0
    # @example Fit whole major intervals inside minimum margins
    #   ruler = Sevgi::Sundries::Ruler.new(brut: 103, unit: 1, multiple: 10, margins: [5])
    #   ruler.n       # => 9
    #   ruler.margins # => [6.5, 6.5]
    #   ruler.waste   # => 13.0
    # @example Preserve an asymmetric margin difference
    #   ruler = Sevgi::Sundries::Ruler.new(brut: 100, unit: 1, multiple: 10, margins: [5, 15])
    #   ruler.margins # => [5.0, 15.0]
    #   ruler.ds.last # => 80.0
    # @see Sevgi::Sundries::Grid
    class Ruler < Interval
      # Returns the full available span before fitting.
      # @return [Float]
      attr_reader :brut

      # Returns the fitted margin after the interval.
      # @return [Float]
      attr_reader :finish

      # Returns the fitted margin before the interval.
      # @return [Float]
      attr_reader :start

      # Returns the source subinterval.
      # @return [Sevgi::Sundries::Interval]
      attr_reader :sub

      # Creates a ruler fitted into the given span.
      # @param brut [Numeric] full available span
      # @param unit [Numeric] subinterval unit length
      # @param multiple [Integer] number of subinterval units per major interval
      # @param margins [Array<Numeric>] one symmetric or two start/end minimum margins
      # @return [void]
      # @raise [Sevgi::ArgumentError] when brut is not numeric
      # @raise [Sevgi::ArgumentError] when brut is not finite
      # @raise [Sevgi::ArgumentError] when brut is negative
      # @raise [Sevgi::ArgumentError] when unit is not numeric
      # @raise [Sevgi::ArgumentError] when unit is not finite
      # @raise [Sevgi::ArgumentError] when unit is not positive
      # @raise [Sevgi::ArgumentError] when multiple is not a positive integer
      # @raise [Sevgi::ArgumentError] when margins does not contain one or two values
      # @raise [Sevgi::ArgumentError] when a margin is not numeric
      # @raise [Sevgi::ArgumentError] when a margin is not finite
      # @raise [Sevgi::ArgumentError] when a margin is negative
      # @raise [Sevgi::ArgumentError] when the fitting span is negative
      def initialize(brut:, unit:, multiple:, margins: [0.0])
        @brut = non_negative_number(brut, "Ruler brut")
        unit = positive_number(unit, "Ruler unit")
        multiple = positive_integer(multiple, "Ruler multiple")
        @sub = Interval.new(unit, multiple)
        span, start, finish = fitting_span(margins)

        n = divide(unit:, multiple:, span:)

        super(@sub, n)
        @start, @finish = fitted_margins(start, finish, span)
      end

      # Returns a ruler where the source subinterval is flattened into units.
      # @example Expand major intervals into individual units
      #   ruler = Sevgi::Sundries::Ruler.new(brut: 103, unit: 1, multiple: 10, margins: [5])
      #   ruler.expand.n # => 90
      #   ruler.ms.size  # => 91
      # @return [Sevgi::Sundries::Ruler]
      def expand = self.class.new(unit: sub.u, multiple: 1, brut: d + waste, margins:)

      # Returns fitted start and finish margins.
      # @return [Array<Float>] frozen margin pair
      def margins = @margins ||= [start, finish].freeze

      # Returns minor tick distances across the fitted span.
      # The memoized collection is frozen and must be treated as immutable.
      # @return [Array<Float>] frozen minor tick distances
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

      private

      def fitted_margins(start, finish, span)
        extra = (span - d) / 2.0
        [start + extra, finish + extra]
      end

      def fitting_span(margins)
        start, finish = margin_pair(margins)
        span = brut - start - finish
        ArgumentError.("Ruler fitting span must not be negative") if span.negative?

        [span, start, finish]
      end

      def margin_pair(values)
        unless values.is_a?(::Array) && [1, 2].include?(values.size)
          ArgumentError.("Ruler margins must contain one or two values")
        end

        values = [values.first, values.first] if values.one?
        values.map { non_negative_number(it, "Ruler margin") }
      end

      protected

      # Computes the number of major intervals fitting in the available span.
      # @param unit [Numeric] subinterval unit length
      # @param multiple [Integer] number of subinterval units per major interval
      # @param span [Numeric] span available after margins
      # @return [Integer]
      def divide(unit:, multiple:, span:) = F.count(span, unit * multiple)
    end

    # Ruler variant that always chooses an even number of major intervals.
    #
    # If ordinary fitting produces an odd count, one complete major interval is
    # removed and the additional space is distributed through the margins.
    # @example Reserve symmetric waste when an odd count would fit
    #   ruler = Sevgi::Sundries::RulerEven.new(brut: 50, unit: 1, multiple: 10)
    #   ruler.n       # => 4
    #   ruler.margins # => [5.0, 5.0]
    class RulerEven < Ruler
      protected

      # Computes an even number of major intervals fitting in the available span.
      # @return [Integer]
      def divide(...) = (n = super).even? ? n : (n - 1)
    end
  end
end
