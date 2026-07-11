# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # Inkscape-specific SVG DSL helpers.
      module Inkscape
        # Adds Inkscape template metadata.
        # @param name [String] template name
        # @param desc [String, nil] short description
        # @param author [String, nil] author
        # @param date [String, nil] date
        # @param keywords [Array<String>, String, nil] keywords
        # @return [Sevgi::Graphics::Element] template metadata element
        def InkscapeTemplateInfo(name:, desc: nil, author: nil, date: nil, keywords: nil)
          Element(:"inkscape:_templateinfo") do
            Element(:"inkscape:_name", name)
            Element(:"inkscape:_shortdesc", desc) if desc
            Element(:"inkscape:date", date) if date
            Element(:"inkscape:author", author) if author
            Element(:"inkscape:_keywords", [*keywords].join(" ")) if keywords
          end
        end

        # Renders a callable module inside a group.
        # @param mod [Module] callable drawing module
        # @param args [Array<Object>] callable arguments
        # @param kwargs [Hash] group attributes
        # @yield forwards customization to the callable module
        # @yieldreturn [Object] callable customization result
        # @return [Sevgi::Graphics::Element] group element
        # @raise [Sevgi::ArgumentError] when mod is not a plain module
        def Group(mod, *args, **kwargs, &block)
          kwargs = kwargs.merge(id: F.demodulize(mod).to_sym) unless kwargs.key?(:id)
          g(**kwargs) { Call(mod, *args, &block) }
        end

        # Renders a callable module inside an Inkscape layer.
        # @param mod [Module] callable drawing module
        # @param args [Array<Object>] callable arguments
        # @param kwargs [Hash] layer attributes
        # @yield forwards customization to the callable module
        # @yieldreturn [Object] callable customization result
        # @return [Sevgi::Graphics::Element] layer element
        # @raise [Sevgi::ArgumentError] when mod is not a plain module
        def Layer(mod, *args, **kwargs, &block)
          kwargs = kwargs.merge(id: F.demodulize(mod).to_sym) unless kwargs.key?(:id)
          layer(**kwargs) { Call(mod, *args, &block) }
        end

        # Renders a callable module inside an insensitive Inkscape layer.
        # @param mod [Module] callable drawing module
        # @param args [Array<Object>] callable arguments
        # @param kwargs [Hash] layer attributes
        # @yield forwards customization to the callable module
        # @yieldreturn [Object] callable customization result
        # @return [Sevgi::Graphics::Element] layer element
        # @raise [Sevgi::ArgumentError] when mod is not a plain module
        def Layer!(mod, *args, **kwargs, &block)
          kwargs = kwargs.merge(id: F.demodulize(mod).to_sym) unless kwargs.key?(:id)
          layer!(**kwargs) { Call(mod, *args, &block) }
        end

        # @overload layer(**attributes)
        #   Builds an Inkscape layer group.
        #   @param attributes [Hash] layer attributes
        #   @yield evaluates the drawing DSL in the layer
        #   @yieldreturn [Object] ignored block result
        #   @return [Sevgi::Graphics::Element] layer group
        def layer(**, &block)
          g("inkscape:groupmode": "layer", **, &block)
        end

        # @overload layer!(**attributes)
        #   Builds an insensitive Inkscape layer group.
        #   @param attributes [Hash] layer attributes
        #   @yield evaluates the drawing DSL in the layer
        #   @yieldreturn [Object] ignored block result
        #   @return [Sevgi::Graphics::Element] layer group
        def layer!(**, &block)
          layer("sodipodi:insensitive": "true", **, &block)
        end

        # Builds an Inkscape namedview containing page elements.
        # @param pages [Array<Hash>] page attribute hashes
        # @param id [String] namedview id
        # @yield [page] customizes each generated page element
        # @yieldparam page [Sevgi::Graphics::Element] generated page element
        # @yieldreturn [Object] ignored customization result
        # @return [Sevgi::Graphics::Element] namedview element
        def Pages(*pages, id: "namedview", **, &block)
          Element(:"sodipodi:namedview", id:, **) do
            pages.each_with_index do |page, i|
              id = page[:id] || "page-#{i + 1}"
              x, y, width, height = page.values_at(*%i[x y width height])
              element = Element(:"inkscape:page", id:, x:, y:, width:, height:)
              yield(element) if block
            end
          end
        end

        # Builds a tabular set of Inkscape pages.
        # @param rows [Integer] number of rows
        # @param cols [Integer] number of columns
        # @param width [Numeric] page width
        # @param height [Numeric] page height
        # @param gap [Numeric] gap between pages
        # @param id [String] namedview id
        # @return [Array<Array>] matrix entries as x, y, and label tuples
        def PagesTabular(rows:, cols:, width:, height:, gap:, id: "namedview", **)
          [].tap do |matrix|
            Element(:"sodipodi:namedview", id:) do
              rows.times do |row|
                cols.times do |col|
                  matrix << (x, y, label = col * (width + gap), row * (height + gap), "#{row + 1}x#{col + 1}")
                  Element(:"inkscape:page", id: "pageview-#{label}", x:, y:, width:, height:, **)
                end
              end
            end
          end
        end

        # Internal symbol which does not show up Symbols Menu
        # @overload symbol!(**attributes)
        #   Builds an Inkscape symbol group hidden from the symbols menu.
        #   @param attributes [Hash] symbol attributes
        #   @yield evaluates the drawing DSL in the symbol group
        #   @yieldreturn [Object] ignored block result
        #   @return [Sevgi::Graphics::Element] symbol group
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
