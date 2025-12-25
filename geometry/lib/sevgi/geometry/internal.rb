# frozen_string_literal: true

module Sevgi
  module Geometry
    module Tuple
      def self.[](klass, arg)
        case arg
        when ::Array
          Error.("Array must have 2 elements: #{arg}", arg) unless arg.size == 2
          Error.("Must be a numeric array: #{arg}")         unless arg.all? { it.is_a?(::Numeric) }

          klass.send(:new, *arg)
        when klass then arg
        else Error.("Must be an Array or #{klass}: #{arg}")
        end
      end
    end

    private_constant :Tuple

    module Tuples
      def self.[](klass, *args) = args.map { Tuple[klass, it] }
    end

    private_constant :Tuples
  end
end
