# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Inkscape
        def InkscapeTemplateInfo(name:, desc: nil, author: nil, date: nil, keywords: nil)
          Element(:"inkscape:_templateinfo") do
            Element(:"inkscape:_name", name)
            Element(:"inkscape:_shortdesc", desc) if desc
            Element(:"inkscape:date", date) if date
            Element(:"inkscape:author", author) if author
            Element(:"inkscape:_keywords", [ *keywords ].join(" ")) if keywords
          end
        end

        def Group(mod, *args, **kwargs, &block)
          kwargs = kwargs.merge(id: F.demodulize(mod).to_sym) unless kwargs.key?(:id)
          g(**kwargs) { Call(mod, *args, &block) }
        end

        def Layer(mod, *args, **kwargs, &block)
          kwargs = kwargs.merge(id: F.demodulize(mod).to_sym) unless kwargs.key?(:id)
          layer(**kwargs) { Call(mod, *args, &block) }
        end

        def Layer!(mod, *args, **kwargs, &block)
          kwargs = kwargs.merge(id: F.demodulize(mod).to_sym) unless kwargs.key?(:id)
          layer!(**kwargs) { Call(mod, *args, &block) }
        end

        def layer(**, &block)
          g("inkscape:groupmode": "layer", **, &block)
        end

        def layer!(**, &block)
          layer("sodipodi:insensitive": "true", **, &block)
        end

        def Pages(*pages, id: "namedview", **, &block) # rubocop:disable Metrics/MethodLength
          Element(:"sodipodi:namedview", id:, **) do
            pages.each_with_index do |page, i|
              id = page[:id] || "page-#{i + 1}"
              x, y, width, height = page.values_at(*%i[ x y width height ])
              element = Element(:"inkscape:page", id:, x:, y:, width:, height:)
              yield(element) if block
            end
          end
        end

        def PagesTabular(rows:, cols:, width:, height:, gap:, id: "namedview", **) # rubocop:disable Metrics/MethodLength
          [].tap do |matrix|
            Element(:"sodipodi:namedview", id:) do
              rows.times do |row|
                cols.times do |col|
                  matrix << (x, y, label = col * (height + gap), row * (width + gap), "#{row + 1}x#{col + 1}")
                  Element(:"inkscape:page", id: "pageview-#{label}", x:, y:, width:, height:, **)
                end
              end
            end
          end
        end

        # Internal symbol which does not show up Symbols Menu
        def symbol!(**, &block)
          if Is?(:defs)
            g(role: "inkscape:symbol", **, &block)
          else
            defs { g(role: "inkscape:symbol", **, &block) }
          end
        end

        def Symbol!(mod, *args, **kwargs, &block)
          kwargs = kwargs.merge(id: F.demodulize(mod).to_sym) unless kwargs.key?(:id)
          symbol!(**kwargs) { Call(mod, *args, &block) }
        end
      end
    end
  end
end
