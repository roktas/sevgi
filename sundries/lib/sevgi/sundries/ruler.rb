# frozen_string_literal: true

module Sevgi
  module Sundries
    #
    # <----------------------------------- d = n x u --------------------------------->
    #
    # <--------------h = d / 2 --------------->
    #
    # |---------+---------+---------+---------|---------+---------+---------+---------|
    #
    #           <--- u --->
    #
    class Interval
      def self.[](e, n) = new(e, n)

      attr_reader :n, :u

      def initialize(e, n) = (@u, @n = measure(e), n)

      def [](i)            = ds[i]

      def count(length)    = (d / length.to_f).to_i

      def d                = @d  ||= n * u

      def ds               = @ds ||= Array.new(n + 1) { |i| i * u }

      def h                = @h ||= d / 2.0

      def hs               = @hs ||= Array.new(n) { |i| u * (0.5 + i) }

      def nds              = @nds ||= ds.size - 1

      def nhs              = @nhs ||= hs.size - 1

      alias_method :length, :d

      private

        def measure(e)
          return e.to_f if e.is_a?(::Numeric)

          raise(NoMethodError, "#{e.class}#length must be implemented") unless e.respond_to?(:length)

          e.length
        end
    end

    #
    # <------------------------ d = n x sd -----------------------------><--- waste = 2 x margin --->
    # <----- u  = unit x multiple ----->
    # <------ sd = su x sn        ----->                            (computed margin >= given margin)
    #
    # |----------+----------+----------|----------+----------+----------|···························|
    #
    # <----------------------------------------- brut ---------------------------------------------->
    #
    class Ruler < Interval
      attr_reader :brut, :sub

      def initialize(brut:, unit:, multiple:, margin: 0.0)
        super(@sub = Interval.new(unit, multiple), divide(unit:, multiple:, brut: (@brut = brut.to_f), margin:))
      end

      def expand = self.class.new(unit: sub.u, multiple: 1, brut: d + waste, margin:)

      def margin = @margin ||= waste / 2.0

      def ms     = @ms ||= expand.ds

      def waste  = @waste ||= brut - d

      def sn     = @sub.n

      def sd     = @sub.d

      def su     = @sub.u

      protected

        def divide(unit:, multiple:, brut:, margin:) = F.count((brut - 2 * margin), unit * multiple)
    end

    class RulerEven < Ruler
      protected

        def divide(...) = (n = super).even? ? n : (n - 1)
    end
  end
end
