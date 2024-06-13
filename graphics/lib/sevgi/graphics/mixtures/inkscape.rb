# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module Inkscape
        module InstanceMethods
          def InkscapeTemplateInfo(name:, desc: nil, author: nil, date: nil, keywords: nil)
            Element(:"inkscape:_templateinfo") do
              Element(:"inkscape:_name", name)
              Element(:"inkscape:_shortdesc", desc) if desc
              Element(:"inkscape:date", date) if date
              Element(:"inkscape:author", author) if author
              Element(:"inkscape:_keywords", [ *keywords ].join(" ")) if keywords
            end
          end

          def Layer(mod, *args, **kwargs, &block)
            kwargs = kwargs.merge(id: F.demodulize(mod).to_sym) unless kwargs.key?(:id)
            layer(**kwargs) { Call(mod, *args, &block) }
          end

          def layer(**, &block)
            g("inkscape:groupmode": "layer", "sodipodi:insensitive": "true", **, &block)
          end

          # Internal symbol which does not show up Symbols Menu
          def symbol!(**, &block)
            if Is?(:defs)
              g(role: "inkscape:symbol", **, &block)
            else
              defs { g(role: "inkscape:symbol", **, &block) }
            end
          end
        end
      end
    end
  end
end
