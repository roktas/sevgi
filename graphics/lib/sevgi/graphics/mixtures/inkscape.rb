# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # Inkscape-specific SVG DSL helpers.
      module Inkscape
        # Normalizes callable wrapper attributes outside the DSL method surface.
        # @api private
        module Wrapper
          # Returns owned wrapper attributes with a stable default id when the module is named.
          # @param mod [Module] callable drawing module
          # @param attributes [Hash] wrapper attributes
          # @return [Hash{Symbol => Object}] normalized attributes
          # @raise [Sevgi::ArgumentError] when attributes contains colliding names
          def self.attributes(mod, attributes)
            defaults = mod.name ? {id: F.demodulize(mod.name).to_sym} : {}
            Attribute.defaults(attributes, **defaults)
          end
        end

        private_constant :Wrapper

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
        # Named modules default the group id to their final constant name. Anonymous modules omit the id unless supplied.
        # @example Supply a stable id for an anonymous callable
        #   drawing = Module.new do
        #     extend Sevgi::Graphics::Module
        #     def call = circle r: 5
        #   end
        #   Sevgi::Graphics.SVG(:inkscape) { Group drawing, attributes: {id: "drawing"} }
        # @param mod [Module] module extended with {Sevgi::Graphics::Module}
        # @param args [Array<Object>] callable arguments
        # @param attributes [Hash] group attributes; String and Symbol names are normalized and must not collide
        # @param kwargs [Hash] callable keyword arguments
        # @yield forwards customization to the callable module
        # @yieldreturn [Object] callable customization result
        # @return [Sevgi::Graphics::Element] group element
        # @raise [Sevgi::ArgumentError] when mod is not a callable drawing module or attributes is not a Hash
        def Group(mod, *args, attributes: {}, **kwargs, &block)
          Graphics::Module.__send__(:callables, mod)
          ArgumentError.("Group attributes must be a Hash") unless attributes.is_a?(::Hash)
          attributes = Wrapper.attributes(mod, attributes)
          g(**attributes) { Call(mod, *args, **kwargs, &block) }
        end

        # Renders a callable module inside an Inkscape layer.
        # Named modules default the layer id to their final constant name. Anonymous modules omit the id unless supplied.
        # @param mod [Module] module extended with {Sevgi::Graphics::Module}
        # @param args [Array<Object>] callable arguments
        # @param attributes [Hash] layer attributes; String and Symbol names are normalized and must not collide
        # @param kwargs [Hash] callable keyword arguments
        # @yield forwards customization to the callable module
        # @yieldreturn [Object] callable customization result
        # @return [Sevgi::Graphics::Element] layer element
        # @raise [Sevgi::ArgumentError] when mod is not a callable drawing module or attributes is not a Hash
        def Layer(mod, *args, attributes: {}, **kwargs, &block)
          Graphics::Module.__send__(:callables, mod)
          ArgumentError.("Layer attributes must be a Hash") unless attributes.is_a?(::Hash)
          attributes = Wrapper.attributes(mod, attributes)
          layer(**attributes) { Call(mod, *args, **kwargs, &block) }
        end

        # Renders a callable module inside an insensitive Inkscape layer.
        # Named modules default the layer id to their final constant name. Anonymous modules omit the id unless supplied.
        # @param mod [Module] module extended with {Sevgi::Graphics::Module}
        # @param args [Array<Object>] callable arguments
        # @param attributes [Hash] layer attributes; String and Symbol names are normalized and must not collide
        # @param kwargs [Hash] callable keyword arguments
        # @yield forwards customization to the callable module
        # @yieldreturn [Object] callable customization result
        # @return [Sevgi::Graphics::Element] layer element
        # @raise [Sevgi::ArgumentError] when mod is not a callable drawing module or attributes is not a Hash
        def Layer!(mod, *args, attributes: {}, **kwargs, &block)
          Graphics::Module.__send__(:callables, mod)
          ArgumentError.("Layer attributes must be a Hash") unless attributes.is_a?(::Hash)
          attributes = Wrapper.attributes(mod, attributes)
          layer!(**attributes) { Call(mod, *args, **kwargs, &block) }
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

        # Validates and constructs Inkscape page collections outside the DSL method surface.
        # @api private
        module Pagination
          class << self
            # Builds a namedview from normalized page attributes.
            # @param context [Sevgi::Graphics::Element] DSL element receiving the namedview
            # @param pages [Array<Hash>] page attributes
            # @param namedview [Hash] namedview attributes
            # @param page [Hash] shared page attributes
            # @return [Sevgi::Graphics::Element] namedview element
            # @raise [Sevgi::ArgumentError] when an attribute channel or page is invalid
            def call(context, pages, namedview:, page:, &block)
              namedview, page = channels(namedview, page)
              pages = pages.each_with_index.map { |attributes, index| normalize(attributes, page, index) }

              context.Element(:"sodipodi:namedview", **namedview) do
                pages.each do |attributes|
                  element = Element(:"inkscape:page", **attributes)
                  block&.call(element)
                end
              end
            end

            # Generates validated attributes for a rectangular page grid.
            # @return [Array<Hash{Symbol => Object}>] page attribute hashes
            # @raise [Sevgi::ArgumentError] when a count, dimension, or gap is invalid
            def tabular(rows:, cols:, width:, height:, gap:)
              width, height, gap = normalize_grid(rows:, cols:, width:, height:, gap:)

              rows.times.flat_map do |row|
                cols.times.map do |col|
                  x = col * (width + gap)
                  y = row * (height + gap)
                  label = "#{row + 1}x#{col + 1}"
                  {id: "pageview-#{label}", x:, y:, width:, height:}
                end
              end
            end

            private

            # Validates and normalizes the namedview and page-default channels.
            # @return [Array<Hash>] normalized namedview attributes and page defaults
            # @raise [Sevgi::ArgumentError] when either channel is not a Hash or has invalid attributes
            # @api private
            def channels(namedview, page)
              ArgumentError.("Namedview attributes must be a Hash") unless namedview.is_a?(::Hash)
              ArgumentError.("Page attributes must be a Hash") unless page.is_a?(::Hash)
              [Attribute.defaults(namedview, id: "namedview"), Attribute.normalize(page)]
            end

            # Normalizes one explicit or generated page id.
            # @return [Hash{String, Symbol => Object}] attributes beginning with a canonical id
            # @raise [Sevgi::ArgumentError] when String and Symbol ids collide
            # @api private
            def identify(attributes, index)
              id = attributes.key?(:id) ? attributes.delete(:id) : "page-#{index + 1}"
              {id:}.merge(attributes)
            end

            # Normalizes and validates one page.
            # @return [Hash{String, Symbol => Object}] independent page attributes
            # @raise [Sevgi::ArgumentError] when attributes or dimensions are invalid
            # @api private
            def normalize(attributes, defaults, index)
              ArgumentError.("Page #{index + 1} must be a Hash") unless attributes.is_a?(::Hash)
              attributes = defaults.merge(Attribute.normalize(attributes))
              %i[x y].each { number(attributes, it, index) }
              %i[width height].each do |field|
                number(attributes, field, index, positive: true)
              end

              identify(attributes, index)
            end

            # Validates and normalizes page-grid arguments.
            # @return [Array<(Integer, Float)>] normalized width, height, and gap
            # @raise [Sevgi::ArgumentError] when a count, dimension, or gap is invalid
            # @api private
            def normalize_grid(rows:, cols:, width:, height:, gap:)
              {rows:, cols:}.each do |field, count|
                unless count.is_a?(::Integer) && count.positive?
                  ArgumentError.("Page #{field} must be a positive Integer")
                end
              end

              [
                Scalar.number(width, context: "page", field: :width, positive: true),
                Scalar.number(height, context: "page", field: :height, positive: true),
                Scalar.number(gap, context: "page", field: :gap, nonnegative: true)
              ]
            end

            # Replaces one page field with its normalized SVG number.
            # @return [Integer, Float] normalized number
            # @api private
            def number(attributes, field, index, **range)
              key = attributes.key?(field) ? field : field.to_s
              attributes[key] = Scalar.number(value(attributes, field, index), context: "page", field:, **range)
            end

            # Returns one required page field.
            # @return [Object] page field value
            # @raise [Sevgi::ArgumentError] when the field is absent
            # @api private
            def value(attributes, field, index)
              attributes.fetch(field) do
                attributes.fetch(field.to_s) { ArgumentError.("Page #{index + 1} requires #{field}") }
              end
            end
          end
        end

        private_constant :Pagination

        # Builds an Inkscape namedview containing page elements.
        # @example Build explicit pages with separate namedview and page attributes
        #   Pages(
        #     {x: 0, y: 0, width: 100, height: 50, label: "front"},
        #     namedview: {id: "views"},
        #     page: {class: "print"}
        #   )
        # @param pages [Array<Hash>] page attribute hashes; numeric page fields are normalized to SVG numbers
        # @param namedview [Hash] namedview attributes; String and Symbol names are normalized and must not collide
        # @param page [Hash] page defaults; normalized page attributes override these defaults by name
        # @yield [page] customizes each generated page element
        # @yieldparam page [Sevgi::Graphics::Element] generated page element
        # @yieldreturn [Object] ignored customization result
        # @return [Sevgi::Graphics::Element] namedview element
        # @raise [Sevgi::ArgumentError] when an attribute channel, page, coordinate, or dimension is invalid
        def Pages(*pages, namedview: {}, page: {}, &block) = Pagination.call(self, pages, namedview:, page:, &block)

        # Builds a tabular set of Inkscape pages.
        # @example Build a page grid using the same attribute channels as {#Pages}
        #   PagesTabular(
        #     rows: 2, cols: 3, width: 100, height: 50, gap: 5,
        #     namedview: {id: "views"}, page: {class: "print"}
        #   )
        # @param rows [Integer] number of rows
        # @param cols [Integer] number of columns
        # @param width [Numeric] finite positive page width, normalized to an SVG number
        # @param height [Numeric] finite positive page height, normalized to an SVG number
        # @param gap [Numeric] finite non-negative gap, normalized to an SVG number
        # @param namedview [Hash] namedview attributes; String and Symbol names are normalized and must not collide
        # @param page [Hash] page defaults; normalized page attributes override these defaults by name
        # @yield [page] customizes each generated page element
        # @yieldparam page [Sevgi::Graphics::Element] generated page element
        # @yieldreturn [Object] ignored customization result
        # @return [Sevgi::Graphics::Element] namedview element
        # @raise [Sevgi::ArgumentError] when counts, dimensions, gap, or an attribute channel is invalid
        # @see #Pages
        def PagesTabular(rows:, cols:, width:, height:, gap:, namedview: {}, page: {}, &block)
          pages = Pagination.tabular(rows:, cols:, width:, height:, gap:)
          Pages(*pages, namedview:, page:, &block)
        end

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
