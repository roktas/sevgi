# frozen_string_literal: true

require "forwardable"

module Sevgi
  module Graphics
    # SVG canvas size, margins, viewport, and viewBox.
    class Canvas
      ORIGIN_FIELDS = %i[x y].freeze
      REPLACEMENTS = %i[width height unit name margins].freeze
      private_constant :ORIGIN_FIELDS, :REPLACEMENTS

      # @overload call(arg = Undefined, **kwargs)
      #   Builds a canvas from a paper profile or explicit size.
      #   @param arg [Sevgi::Graphics::Paper, Symbol, String, Sevgi::Undefined] paper profile or paper object
      #   @param kwargs [Hash] canvas keyword arguments
      #   @return [Sevgi::Graphics::Canvas]
      #   @raise [Sevgi::ArgumentError] when the paper profile is unknown
      def self.call(...) = from_paper(...)

      # Builds a canvas from a paper profile or explicit size.
      # @param arg [Sevgi::Graphics::Paper, Symbol, String, Sevgi::Undefined] paper profile or paper object
      # @param kwargs [Hash] canvas keyword arguments
      # @return [Sevgi::Graphics::Canvas]
      # @raise [Sevgi::ArgumentError] when the paper profile is unknown
      def self.from_paper(arg = Undefined, **kwargs)
        case arg
        when Undefined
          new(**kwargs)
        else
          new(**paper(arg).to_h, **kwargs)
        end
      end

      def self.paper(arg)
        case arg
        when Paper
          arg
        when ::Symbol, ::String
          ArgumentError.("Unknown paper profile: #{arg}") unless Paper.exist?(arg)

          Paper.public_send(arg)
        else
          ArgumentError.("Argument must be a Paper symbol: #{arg}")
        end
      end

      private_class_method :paper

      extend Forwardable

      def_delegators :@margin, *Margin.members
      def_delegators :@size, *Paper.members

      # @!attribute [r] size
      #   @return [Sevgi::Graphics::Paper] paper size object
      # @!attribute [r] margin
      #   @return [Sevgi::Graphics::Margin] canvas margins
      # @!attribute [r] inner
      #   @return [Sevgi::Graphics::Paper] inner paper after margins
      attr_reader :size, :margin, :inner

      # Creates a canvas with finite real dimensions greater than zero and margins that leave a positive inner area.
      # @param width [Numeric] canvas width
      # @param height [Numeric] canvas height
      # @param unit [Symbol, String] SVG unit
      # @param name [Symbol, String] paper name
      # @param margins [Array<Numeric>] margin shorthand values
      # @return [void]
      # @raise [Sevgi::ArgumentError] when margins or numeric dimensions are invalid
      def initialize(width:, height:, unit: "mm", name: :custom, margins: [])
        @size = Paper[width, height, unit, name]
        @margin = Margin[*margins]

        compute
        freeze
      end

      # @overload attributes(origin = Undefined)
      #   Returns SVG root viewport attributes.
      #   @param origin [Numeric, Array<Numeric>, nil, Sevgi::Undefined] viewBox origin
      #   @return [Hash]
      #   @raise [Sevgi::ArgumentError] when origin is invalid
      def attributes(...) = {**viewport, viewBox: viewbox(...)}

      # Returns SVG width and height attributes.
      # @return [Hash]
      def viewport = {width: "#{width}#{unit}", height: "#{height}#{unit}"}

      # Returns the SVG viewBox string.
      # @param origin [Numeric, Array<Numeric>, nil, Sevgi::Undefined] viewBox origin
      # @return [String]
      # @raise [Sevgi::ArgumentError] when origin is invalid
      def viewbox(origin = Undefined) = prettify(*originate(origin), width, height).join(" ")

      # Returns a canvas with selected fields replaced.
      # @param kwargs [Hash] replacement options
      # @option kwargs [Numeric] :width replacement canvas width
      # @option kwargs [Numeric] :height replacement canvas height
      # @option kwargs [Symbol, String] :unit replacement SVG unit
      # @option kwargs [Symbol, String] :name replacement paper name
      # @option kwargs [Array<Numeric>] :margins replacement margin shorthand values
      # @return [Sevgi::Graphics::Canvas]
      # @raise [Sevgi::ArgumentError] when an unknown option is supplied
      # @raise [Sevgi::ArgumentError] when a replacement value is invalid
      def with(**kwargs)
        unknown = kwargs.keys - REPLACEMENTS

        ArgumentError.("Unknown canvas option: #{unknown.first}") unless unknown.empty?

        margins = kwargs.fetch(:margins, margin.to_a)
        replacements = kwargs.dup.tap { it.delete(:margins) }

        self.class.new(**size.to_h, **replacements, margins:)
      end

      private

      def compute
        @inner = size.with(**inner_size)
        ensure_inner_area
      end

      def ensure_inner_area
        return if @inner.width.positive? && @inner.height.positive?

        ArgumentError.("Canvas margins must leave a positive inner area")
      end

      def inner_size
        {
          width: width - margin.left - margin.right,
          height: height - margin.top - margin.bottom
        }
      end

      def originate(origin)
        case origin
        when Undefined
          [-margin.left, -margin.top]
        when ::Numeric, ::NilClass
          scalar_origin(origin)
        when ::Array
          pair(origin)
        else
          ArgumentError.("Canvas origin must be an Array")
        end
      end

      def coordinate!(field, value)
        return 0.0 if value.nil?

        Scalar.finite(value, context: "canvas origin", field:)
      end

      def scalar_origin(origin)
        coordinate!(:origin, origin || 0).then { [it, it] }
      end

      def prettify(*floats)
        floats.map { (it % 1).zero? ? it.to_i : it }
      end

      def pair(array)
        ArgumentError.("Canvas origin must have exactly two coordinates") unless array.size == 2

        ORIGIN_FIELDS.zip(array).map { |field, value| coordinate!(field, value) }
      end
    end
  end
end
