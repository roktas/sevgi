# frozen_string_literal: true

module Sevgi
  module Geometry
    class Ellipse
      # Recovers ellipse axes and the Arc parameter correspondence after a linear transform.
      # @api private
      class Affine
        def initialize(ellipse)
          @ellipse = ellipse
        end

        # rubocop:disable-next Metrics/AbcSize, Metrics/MethodLength
        def transform(method, *args, **kwargs)
          axes = [Point[1, 0], Point[0, 1]].map { it.public_send(method, *args, **kwargs) }
          direction = orientation(*axes)
          center = @ellipse.position.public_send(method, *args, **kwargs)
          u, v = basis.map { it.public_send(method, *args, **kwargs) }
          ellipse = recover(u, v, center)

          if @ellipse.is_a?(Circle) && similarity?(*axes)
            ellipse = Circle[::Math.hypot(u.x, u.y), position: center]
          end

          local = u.rotate(-ellipse.rotation)
          phase = F.to_degrees(::Math.atan2(local.y / ellipse.ry, local.x / ellipse.rx))
          [ellipse, phase, direction]
        end

        private

        def basis
          [Point[@ellipse.rx, 0], Point[0, @ellipse.ry]].map { it.rotate(@ellipse.rotation) }
        end

        # rubocop:disable-next Metrics/AbcSize
        def orientation(u, v)
          scale = [u.x.abs, u.y.abs, v.x.abs, v.y.abs].max
          Error.("Ellipse transform is singular") if scale.zero?

          a, b = (u.x / scale) * (v.y / scale), (u.y / scale) * (v.x / scale)
          determinant = a - b
          if determinant.abs <= 8 * Float::EPSILON * [a.abs, b.abs].max
            Error.("Ellipse transform is singular at floating-point precision")
          end

          determinant.positive? ? 1 : -1
        end

        # rubocop:disable-next Metrics/AbcSize
        def recover(u, v, center)
          scale = [u.x.abs, u.y.abs, v.x.abs, v.y.abs].max
          Error.("Ellipse transform collapses its radii") if scale.zero?

          ux, uy, vx, vy = [u.x, u.y, v.x, v.y].map { it / scale }
          a, b, c = (ux * ux) + (vx * vx), (ux * uy) + (vx * vy), (uy * uy) + (vy * vy)
          major = ::Math.sqrt((a + c + ::Math.hypot(a - c, 2 * b)) / 2)
          # The determinant avoids cancellation in the smaller eigenvalue.
          minor = ((ux * vy) - (uy * vx)).abs / major
          rotation = F.to_degrees(::Math.atan2(2 * b, a - c)) / 2
          Ellipse[major * scale, minor * scale, position: center, rotation:]
        end

        def similarity?(u, v)
          ((u.x * v.x) + (u.y * v.y)).zero? && ::Math.hypot(u.x, u.y) == ::Math.hypot(v.x, v.y)
        end
      end

      private_constant :Affine
    end
  end
end
