# frozen_string_literal: true

require "forwardable"

module Sevgi
  module Graphics
    # Immutable SVG canvas size, margins, viewport, and viewBox.
    #
    # `size` is the outer paper. `inner` subtracts the margins but remains a
    # size value, not a positioned rectangle. By default the viewBox origin is
    # the negative left/top margin, so drawing coordinates `(0, 0)` begin at the
    # inner area's top-left while the SVG viewport still includes the margins.
    # Pass nil to {#viewbox} or {#attributes} for a literal zero origin.
    # @example Build from a paper profile or an explicit size
    #   page = Sevgi::Graphics::Canvas.from_paper(:a4, margins: [10])
    #   icon = Sevgi::Graphics::Canvas.call(width: 24, height: 24, unit: :px)
    #   page.viewbox       # uses the negative left and top margins as its origin
    #   icon.viewbox(nil)  # uses `0 0` as its origin
    # @see Sevgi::Graphics::Document
    # @see Sevgi::Sundries::Grid
    class Canvas
      DEFAULTS = {unit: "mm", name: :custom, margins: []}.freeze
      FIELDS = %i[width height unit name margins].freeze
      ORIGIN_FIELDS = %i[x y].freeze
      REQUIRED = %i[width height].freeze
      private_constant :DEFAULTS, :FIELDS, :ORIGIN_FIELDS, :REQUIRED

      # @overload call(paper, **overrides)
      #   Builds a canvas from a paper profile with optional field overrides.
      #   @param paper [Sevgi::Graphics::Paper, Symbol, String] paper object or registered profile
      #   @param overrides [Hash] canvas field overrides
      #   @return [Sevgi::Graphics::Canvas]
      #   @raise [Sevgi::ArgumentError] when the paper or an override is invalid
      # @overload call(width:, height:, unit: "mm", name: :custom, margins: [])
      #   Builds a canvas from an explicit size.
      #   @param width [Numeric] canvas width
      #   @param height [Numeric] canvas height
      #   @param unit [Symbol, String] SVG unit
      #   @param name [Symbol, String] paper name
      #   @param margins [Array<Numeric>] margin shorthand values
      #   @return [Sevgi::Graphics::Canvas]
      #   @raise [Sevgi::ArgumentError] when a required field is omitted or a value is invalid
      def self.call(paper = Undefined, **fields)
        paper.equal?(Undefined) ? new(**fields) : from_paper(paper, **fields)
      end

      # @overload from_paper(paper, **overrides)
      #   Builds a canvas from a paper profile with optional field overrides.
      #   @param paper [Sevgi::Graphics::Paper, Symbol, String] paper object or registered profile
      #   @param overrides [Hash] canvas field overrides
      #   @return [Sevgi::Graphics::Canvas]
      #   @raise [Sevgi::ArgumentError] when the paper is omitted or invalid, or an override is invalid
      # @example Override a registered paper profile
      #   Sevgi::Graphics::Canvas.from_paper(:a4, margins: [10])
      def self.from_paper(paper = Undefined, **overrides)
        ArgumentError.("Paper is required") if paper.equal?(Undefined)

        new(**profile(paper).to_h, **overrides)
      end

      def self.profile(paper)
        case paper
        when Paper
          paper
        when ::Symbol, ::String
          Paper.fetch(paper)
        else
          ArgumentError.("Paper must be a Paper, Symbol, or String: #{paper}")
        end
      end

      private_class_method :profile

      extend Forwardable

      def_delegators :@margin, *Margin.members
      def_delegators :@size, *Paper.members

      # Returns the paper size object.
      # @return [Sevgi::Graphics::Paper]
      attr_reader :size

      # Returns the canvas margins.
      # @return [Sevgi::Graphics::Margin]
      attr_reader :margin

      # Returns the inner paper after margins.
      # @return [Sevgi::Graphics::Paper]
      attr_reader :inner

      # @overload initialize(width:, height:, unit: "mm", name: :custom, margins: [])
      #   Creates a canvas with finite real dimensions greater than zero and margins that leave a positive inner area.
      #   @param width [Numeric] canvas width
      #   @param height [Numeric] canvas height
      #   @param unit [Symbol, String] SVG unit
      #   @param name [Symbol, String] paper name
      #   @param margins [Array<Numeric>] margin shorthand values
      #   @return [void]
      #   @raise [Sevgi::ArgumentError] when a required field is omitted, an option is unknown, or a value is invalid
      def initialize(**fields)
        unknown = fields.keys - FIELDS
        ArgumentError.("Unknown canvas option: #{unknown.first}") unless unknown.empty?
        ArgumentError.("Canvas width and height are required") unless REQUIRED.all? { fields.key?(it) }

        fields = DEFAULTS.merge(fields)

        @size = Paper[*fields.values_at(:width, :height, :unit, :name)]
        @margin = Margin[*fields[:margins]]

        compute
        freeze
      end

      # @overload attributes(origin = Undefined)
      #   Returns SVG root viewport attributes.
      #   Omission uses the negative left and top margins; nil uses zero for both coordinates.
      #   @example Compare margin-aware and zero-origin viewBoxes
      #     canvas = Sevgi::Graphics::Canvas.call(width: 80, height: 50, margins: [5, 10])
      #     canvas.attributes[:viewBox] # => "-10 -5 80 50"
      #     canvas.attributes(nil)[:viewBox] # => "0 0 80 50"
      #   @param origin [Numeric, Array<Numeric>, nil, Sevgi::Undefined] viewBox origin; a scalar sets both coordinates
      #   @return [Hash{Symbol => String}] SVG viewport and viewBox attributes
      #   @raise [Sevgi::ArgumentError] when origin is invalid
      def attributes(...) = {**viewport, viewBox: viewbox(...)}

      # Reports structural canvas equality by size and margins.
      # @example Compare equivalent canvas values
      #   Sevgi::Graphics::Canvas.from_paper(:a4, margins: [10]) ==
      #     Sevgi::Graphics::Canvas.from_paper("a4", margins: [10]) # => true
      # @param other [Object] object to compare
      # @return [Boolean]
      def eql?(other) = self.class == other.class && size.eql?(other.size) && margin.eql?(other.margin)

      # Returns a hash compatible with structural equality.
      # @return [Integer]
      def hash = [self.class, size, margin].hash

      alias == eql?

      # Returns SVG width and height attributes.
      # @return [Hash{Symbol => String}] SVG width and height attributes
      def viewport = {width: "#{width}#{unit}", height: "#{height}#{unit}"}

      # Returns the SVG viewBox string.
      # Omission uses the negative left and top margins; nil uses zero for both coordinates.
      # @param origin [Numeric, Array<Numeric>, nil, Sevgi::Undefined] viewBox origin; a scalar sets both coordinates
      # @return [String]
      # @raise [Sevgi::ArgumentError] when origin is invalid
      def viewbox(origin = Undefined) = prettify(*originate(origin), width, height).join(" ")

      # Returns a canvas with selected fields replaced.
      # Unspecified fields, including margins, retain their current values.
      # @example Derive a canvas while preserving the source
      #   source = Sevgi::Graphics::Canvas.call(width: 80, height: 50, margins: [5])
      #   derived = source.with(width: 100, margins: [10, 5])
      #   source.width # => 80.0
      #   derived.inner.deconstruct # => [90.0, 30.0, :mm, :custom]
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
        unknown = kwargs.keys - FIELDS

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
