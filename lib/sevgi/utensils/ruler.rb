# frozen_string_literal: true

# codebeat:disable[TOO_MANY_IVARS]

module Sevgi
  module Utensils
    #
    # <------------------------------------------------- brut -------------------------------------------------->
    #              <------------------------- length = (n - 1) x minor = (m - 1) x major ----------------------->
    # <-   space  ->         <- minor ->                   <------- major = multiple x minor ------>
    # |............|---------+---------+---------+---------|---------+---------+---------+---------|............|
    #       |
    #       +--> space = minspace + computed space for evenness
    #
    class Ruler
      attr_reader :unit, :multiple, :brut, :minspace

      def initialize(unit:, multiple:, brut:, minspace:)
        @brut, @unit, @minspace = brut.to_f, unit.to_f, minspace.to_f
        @multiple               = multiple
      end

      def halve  = @halve  ||= major / 2.0
      def length = @length ||= (n - 1) * unit
      def major  = @major  ||= multiple * unit
      def space  = @space  ||= brut - length

      def l      = @l      ||= 2 * m - 1
      def ls     = @ls     ||= Array.new(l) { |i| i * halve }

      def m      = @m      ||= even(unit: major) + 1
      def ms     = @ms     ||= Array.new(m) { |i| i * major }

      def n      = @n      ||= even(unit:, multiple:) + 1
      def ns     = @ns     ||= Array.new(n) { |i| i * unit }

      alias_method :minor, :unit

      private

      def even(unit: nil, multiple: 1)
        (n = ((brut - 2 * minspace) / (multiple * unit).to_f).to_i).even? ? n : (n - 1)
        n * multiple
      end
    end
  end
end
