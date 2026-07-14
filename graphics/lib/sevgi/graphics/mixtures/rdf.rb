# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # DSL helpers for RDF and license metadata.
      #
      # @example Add Creative Commons metadata
      #   SVG :inkscape do
      #     License_CC0 title: "Example", creator: "A. Creator"
      #   end
      module RDF
        WORK_OPTIONS = %i[title description creator publisher date language license].freeze
        private_constant :WORK_OPTIONS

        # Adds RDF license metadata inside a metadata element.
        # @param kwargs [Hash] RDF work options
        # @yield evaluates additional RDF work metadata
        # @yieldreturn [Object] ignored block result
        # @return [Sevgi::Graphics::Element] metadata element
        # @raise [Sevgi::ArgumentError] when an option is unknown
        # @see #RDFWork
        def License(**kwargs, &block)
          unknown = kwargs.keys - WORK_OPTIONS
          ArgumentError.("Unknown license options: #{unknown.join(", ")}") unless unknown.empty?

          metadata { RDFWork(**kwargs, &block) }
        end

        # Adds Creative Commons BY license metadata.
        # @param kwargs [Hash] RDF work options
        # @yield evaluates additional RDF work metadata
        # @yieldreturn [Object] ignored block result
        # @return [Sevgi::Graphics::Element] metadata element
        # @raise [Sevgi::ArgumentError] when an option is unknown
        # @see #RDFWork
        def License_CC_BY(**kwargs, &block)
          License(**kwargs, license: "https://creativecommons.org/licenses/by/4.0/", &block)
        end

        # Adds Creative Commons BY-SA license metadata.
        # @param kwargs [Hash] RDF work options
        # @yield evaluates additional RDF work metadata
        # @yieldreturn [Object] ignored block result
        # @return [Sevgi::Graphics::Element] metadata element
        # @raise [Sevgi::ArgumentError] when an option is unknown
        # @see #RDFWork
        def License_CC_BY_SA(**kwargs, &block)
          License(**kwargs, license: "https://creativecommons.org/licenses/by-sa/4.0/", &block)
        end

        # Adds Creative Commons BY-NC license metadata.
        # @param kwargs [Hash] RDF work options
        # @yield evaluates additional RDF work metadata
        # @yieldreturn [Object] ignored block result
        # @return [Sevgi::Graphics::Element] metadata element
        # @raise [Sevgi::ArgumentError] when an option is unknown
        # @see #RDFWork
        def License_CC_BY_NC(**kwargs, &block)
          License(**kwargs, license: "https://creativecommons.org/licenses/by-nc/4.0/", &block)
        end

        # Adds Creative Commons BY-NC-SA license metadata.
        # @param kwargs [Hash] RDF work options
        # @yield evaluates additional RDF work metadata
        # @yieldreturn [Object] ignored block result
        # @return [Sevgi::Graphics::Element] metadata element
        # @raise [Sevgi::ArgumentError] when an option is unknown
        # @see #RDFWork
        def License_CC_BY_NC_SA(**kwargs, &block)
          License(**kwargs, license: "https://creativecommons.org/licenses/by-nc-sa/4.0/", &block)
        end

        # Adds Creative Commons BY-ND license metadata.
        # @param kwargs [Hash] RDF work options
        # @yield evaluates additional RDF work metadata
        # @yieldreturn [Object] ignored block result
        # @return [Sevgi::Graphics::Element] metadata element
        # @raise [Sevgi::ArgumentError] when an option is unknown
        # @see #RDFWork
        def License_CC_BY_ND(**kwargs, &block)
          License(**kwargs, license: "https://creativecommons.org/licenses/by-nd/4.0/", &block)
        end

        # Adds Creative Commons BY-NC-ND license metadata.
        # @param kwargs [Hash] RDF work options
        # @yield evaluates additional RDF work metadata
        # @yieldreturn [Object] ignored block result
        # @return [Sevgi::Graphics::Element] metadata element
        # @raise [Sevgi::ArgumentError] when an option is unknown
        # @see #RDFWork
        def License_CC_BY_NC_ND(**kwargs, &block)
          License(**kwargs, license: "https://creativecommons.org/licenses/by-nc-nd/4.0/", &block)
        end

        # Adds Creative Commons Zero metadata.
        # @param kwargs [Hash] RDF work options
        # @yield evaluates additional RDF work metadata
        # @yieldreturn [Object] ignored block result
        # @return [Sevgi::Graphics::Element] metadata element
        # @raise [Sevgi::ArgumentError] when an option is unknown
        # @see #RDFWork
        def License_CC0(**kwargs, &block)
          License(**kwargs, license: "https://creativecommons.org/publicdomain/zero/1.0/", &block)
        end

        # Adds Free Art License metadata.
        # @param kwargs [Hash] RDF work options
        # @yield evaluates additional RDF work metadata
        # @yieldreturn [Object] ignored block result
        # @return [Sevgi::Graphics::Element] metadata element
        # @raise [Sevgi::ArgumentError] when an option is unknown
        # @see #RDFWork
        def License_LAL(**kwargs, &block) = License(**kwargs, license: "https://artlibre.org/licence/lal/en/", &block)

        # Builds an RDF root element.
        # @param kwargs [Hash] options; RDF currently accepts none
        # @yield evaluates the RDF drawing DSL
        # @yieldreturn [Object] ignored block result
        # @return [Sevgi::Graphics::Element] RDF element
        # @raise [Sevgi::ArgumentError] when no block is given
        # @raise [Sevgi::ArgumentError] when an option is given
        def RDF(**kwargs, &block)
          ArgumentError.("Unknown RDF options: #{kwargs.keys.join(", ")}") unless kwargs.empty?
          ArgumentError.("Block required") unless block

          Element(
            :"rdf:RDF",
            "xmlns:rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
            "xmlns:dc": "http://purl.org/dc/elements/1.1/",
            "xmlns:cc": "http://creativecommons.org/ns#"
          ) do
            Within(&block)
          end
        end

        # Builds a Creative Commons RDF Work element.
        # @param kwargs [Hash] RDF work options
        # @option kwargs [String] :title work title
        # @option kwargs [String] :description work description
        # @option kwargs [String] :creator creator
        # @option kwargs [String] :publisher publisher
        # @option kwargs [String] :date date
        # @option kwargs [String] :language language
        # @option kwargs [String] :license license URL
        #
        # | Option | RDF element |
        # | --- | --- |
        # | `title` | `dc:title` |
        # | `description` | `dc:description` |
        # | `creator` | `dc:creator` |
        # | `publisher` | `dc:publisher` |
        # | `date` | `dc:date` |
        # | `language` | `dc:language` |
        # | `license` | `cc:license` resource |
        # @yield evaluates additional RDF work metadata
        # @yieldreturn [Object] ignored block result
        # @return [Sevgi::Graphics::Element] RDF element
        # @raise [Sevgi::ArgumentError] when an option is unknown
        def RDFWork(**kwargs, &block)
          unknown = kwargs.keys - WORK_OPTIONS
          ArgumentError.("Unknown RDF work options: #{unknown.join(", ")}") unless unknown.empty?

          RDF do
            Element(:"cc:Work", "rdf:about": "") do
              Element(:"dc:format", "image/svg+xml")
              Element(:"dc:type", "rdf:resource": "http://purl.org/dc/dcmitype/StillImage")
              Element(:"dc:title", kwargs[:title]) if kwargs[:title]
              Element(:"dc:description", kwargs[:description]) if kwargs[:description]
              Element(:"dc:creator", kwargs[:creator]) if kwargs[:creator]
              Element(:"dc:publisher", kwargs[:publisher]) if kwargs[:publisher]
              Element(:"dc:date", kwargs[:date]) if kwargs[:date]
              Element(:"dc:language", kwargs[:language]) if kwargs[:language]
              Element(:"cc:license", "rdf:resource": kwargs[:license]) if kwargs[:license]

              Within(&block) if block
            end
          end
        end
      end
    end
  end
end
