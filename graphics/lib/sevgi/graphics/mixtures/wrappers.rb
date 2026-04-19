# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Wrappers
        def Cline(x1: 0, y1: 0, x2:, y2:, **)
          path(d: "M #{x1} #{y1} L #{x2} #{y2}", **)
        end

        def Hline(x1: 0, y1: 0, x2:, **)
          path(d: "M #{x1} #{y1} H #{x2}", **)
        end

        def Symbol(name, **kwargs, &block)
          id    = (words = name.split).map(&:downcase).join("-")
          title = words.map(&:capitalize).join(" ")

          symbol(id:, **kwargs) do
            title(title)
            Within(&block)
          end
        end

        def Vline(x1: 0, y1: 0, y2:, **)
          path(d: "M #{x1} #{y1} V #{y2}", **)
        end

        def cline(x: 0, y: 0, angle:, length:, **)
          dx = length * ::Math.cos(angle.to_f / 180 * ::Math::PI)
          dy = length * ::Math.sin(angle.to_f / 180 * ::Math::PI)
          path(d: "M #{x} #{y} l #{dx} #{dy}", **)
        end

        def css(hash, **)
          style(Content.css(hash), type: "text/css", **)
        end

        def cxline(x: 0, y: 0, angle:, dx:, **)
          dy = dx * ::Math.tan(angle.to_f / 180 * ::Math::PI)
          path(d: "M #{x} #{y} l #{dx} #{dy}", **)
        end

        def cyline(x: 0, y: 0, angle:, dy:, **)
          dx = dy / ::Math.tan(angle.to_f / 180 * ::Math::PI)
          path(d: "M #{x} #{y} l #{dx} #{dy}", **)
        end

        def hline(x: 0, y: 0, length:, **)
          path(d: "M #{x} #{y} h #{length}", **)
        end

        def square(length:, **)
          rect(width: length, height: length, **)
        end

        def vline(x: 0, y: 0, length:, **)
          path(d: "M #{x} #{y} v #{length}", **)
        end
      end
    end
  end
end
