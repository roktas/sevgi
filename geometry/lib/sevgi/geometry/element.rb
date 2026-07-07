# frozen_string_literal: true

module Sevgi
  module Geometry
    class Element
      def self.lined(...) = Lined.build(...)

      def self.arced(...) = Arced.build(...)

      # Core API

      def at(point = nil, dx: 0, dy: 0)
        point = point ? Tuple[Point, point] : position

        translate(
          (point.x - position.x) + dx,
          (point.y - position.y) + dy
        )
      end

      def box = PanicError.("#{self.class}#box must be implemented")

      def equations = PanicError.("#{self.class}#equations must be implemented")

      def ignorable?(precision: nil) = F.zero?(box.width, precision:) && F.zero?(box.height, precision:)

      def position = PanicError.("#{self.class}#position must be implemented")

      def translate(_x, _y) = PanicError.("#{self.class}#translate must be implemented")

      # rubocop:disable Metrics/ClassLength
      class Lined < self
        Open = Class.new(self) do
          def draw!(node, **) = node.polyline(points: points.map { it.deconstruct.join(",") }, **)
        end

        Close = Class.new(self) do
          def self.new_by_points(*points) = super(*points, points.first)

          def draw!(node, **) = node.polygon(points: points.map { it.deconstruct.join(",") }, **)
        end

        # Class methods

        SHORTCUTS = ("A".."Z").to_a.freeze

        # rubocop:disable Metrics/MethodLength
        def self.build(size = Undefined, open: false)
          Class.new(open ? Open : Close) do
            define_singleton_method(:close?) { !open }

            define_singleton_method(:open?) { open }

            define_singleton_method(:poly?) { size == Undefined }

            define_singleton_method(:size) { size }

            unless size == Undefined
              SHORTCUTS[..size.clamp(..SHORTCUTS.size)].each_with_index do |name, i|
                define_method(name) { points[i] or Error.("No such point: #{name}") }
              end

              methods = SHORTCUTS[..size.clamp(..SHORTCUTS.size)].each_cons(2).with_index.map do |names, i|
                define_method(name = names.join) { lines[i] or Error.("No such line: #{name}") }
              end

              alias_method("#{SHORTCUTS[size - 1]}#{SHORTCUTS.first}", methods.last)
            end
          end
          # rubocop:enable Metrics/MethodLength
        end

        def self.[](...) = from_segments(...)

        def self.call(...) = from_points(...)

        def self.from_points(...) = new_by_points(...)

        def self.from_segments(...) = new_by_segments(...)

        def self.new_by_points(...) = new_by_points!(...)

        def self.new_by_points!(*points)
          new do
            @points = Tuples[Point, *points]
          end
        end

        def self.new_by_segments(*segments, position: Origin)
          new do
            @position = Tuple[Point, position]
            @segments = Tuples[Segment, *segments]
          end
        end

        private_class_method(:new)

        def initialize(&block)
          super()

          Error.("Constructor block required") unless block

          instance_exec(&block)

          @points ||= calculate_points_from_segments
          @segments ||= calculate_segments_from_points

          sanitize
        end

        # Core methods

        def approx
          points, segments = points(true), segments(true)
          self.class.send(:new) do
            @points, @segments = points, segments
          end
        end

        def draw(...)
          approx.draw!(...)
        end

        def points(approximate = false)
          approximate ? (@points_approx ||= @points.map(&:approx)) : @points
        end

        def position
          @position ||= points.first
        end

        def segments(approximate = false)
          approximate ? (@segments_approx ||= @segments.map(&:approx)) : @segments
        end

        # Affinity methods

        Geometry::Affinity.instance_methods.each do |transform|
          define_method(transform) do |*args, **kwargs, &block|
            self.class.new_by_points!(*points.map { it.public_send(transform, *args, **kwargs, &block) })
          end
        end

        # Equality methods

        def eql?(other) = self.class == other.class && points(true) == other.points(true)

        def hash = [self.class, *points(true)].hash

        alias == eql?

        # Interaction methods

        def equations = @equations ||= lines.map(&:equation)

        def intersection(equation, precision: nil)
          equations
            .map do |candidate|
              equation.intersect(candidate).map { |point| point.approx(precision) }.select { |point| on?(point) }
            end
            .flatten
            .uniq
        end

        # Properties

        def [](i) = lines[i].tap { |line| Error.("No line exist for index: #{i}") unless line }

        def box = Rect.from_corners([(xs = points.map(&:x)).min, (ys = points.map(&:y)).min], [xs.max, ys.max])

        def call(i) = points[i].tap { Error.("No point exist for index: #{i}") unless it }

        def head = @head ||= segments.first

        def lines
          @lines ||= segments.zip(points[...segments.size]).map { |segment, position|
            segment.line(position)
          }
        end

        def perimeter = @perimeter ||= segments.sum(&:length)

        def tail = @tail ||= segments.last

        # Relation methods

        def inside?(point)
          point = Tuple[Point, point]

          on?(point) || pnpoly(points, point)
        end

        def on?(point)
          point = Tuple[Point, point]

          lines.any? { it.over?(point) }
        end

        def outside?(point) = !inside?(point)

        private

        def calculate_points_from_segments
          Error.("No segments found") unless segments

          [point = position, *segments.map { point = it.ending(point) }].tap do |points|
            # Perfectionist touch
            points[-1] = points.first if points.first.eq?(points.last)
          end
        end

        def calculate_segments_from_points
          Error.("No points found") unless points

          points.each_cons(2).map { Segment.(*it) }
        end

        # rubocop:disable Metrics/MethodLength
        # https://wrfranklin.org/Research/Short_Notes/pnpoly.html
        def pnpoly(vertices, test)
          result = false

          i = 0
          j = vertices.size - 1

          while i < vertices.size
            if (vertices[i].y > test.y) != (vertices[j].y > test.y) &&
                (test.x < ((vertices[j].x - vertices[i].x) *
                  (test.y - vertices[i].y).to_f /
                  (vertices[j].y - vertices[i].y)) +
                  vertices[i].x)
              result = !result
            end

            j = i
            i += 1
          end

          result
        end
        # rubocop:enable Metrics/MethodLength

        def sanitize
          np = self.class.poly? ? points.size : self.class.size + 1
          ns = np - 1

          Error.("Wrong number of points;  expected #{np} where found #{points.size}") unless points.size == np
          Error.("Wrong number of segments; expected #{ns} where found #{segments.size}") unless segments.size == ns
          Error.("Element points must form a closed path") if self.class.close? && !points.first.eq?(points.last)
        end
      end

      class Arced < self
      end
      # rubocop:enable Metrics/ClassLength
    end

    require_relative "elements/line"
    require_relative "elements/parallelogram"
    require_relative "elements/polygon"
    require_relative "elements/polyline"
    require_relative "elements/rect"
    require_relative "elements/triangle"

    require_relative "elements/circle"
    require_relative "elements/curve"
    require_relative "elements/ellipse"
  end
end
