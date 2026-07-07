# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Wrappers
        def LineTo(x2:, y2:, x1: 0, y1: 0, **)
          path(d: "M #{x1} #{y1} L #{x2} #{y2}", **)
        end

        def HLineTo(x2:, x1: 0, y1: 0, **)
          path(d: "M #{x1} #{y1} H #{x2}", **)
        end

        def Symbol(name, **kwargs, &block)
          id = (words = name.split).map(&:downcase).join("-")
          title = words.map(&:capitalize).join(" ")

          symbol(id:, **kwargs) do
            title(title)
            Within(&block)
          end
        end

        def VLineTo(y2:, x1: 0, y1: 0, **)
          path(d: "M #{x1} #{y1} V #{y2}", **)
        end

        def LineBy(angle:, length:, x: 0, y: 0, **)
          dx = length * ::Math.cos(angle.to_f / 180 * ::Math::PI)
          dy = length * ::Math.sin(angle.to_f / 180 * ::Math::PI)
          path(d: "M #{x} #{y} l #{dx} #{dy}", **)
        end

        def css(hash = nil, **attributes)
          hash, attributes = attributes, {} unless hash

          style(Content.css(hash), type: "text/css", **attributes)
        end

        def HLineBy(length:, x: 0, y: 0, **)
          path(d: "M #{x} #{y} h #{length}", **)
        end

        def square(length:, **)
          rect(width: length, height: length, **)
        end

        def VLineBy(length:, x: 0, y: 0, **)
          path(d: "M #{x} #{y} v #{length}", **)
        end
      end
    end
  end
end
