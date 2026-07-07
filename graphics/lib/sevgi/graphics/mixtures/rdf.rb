# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # DSL helpers for RDF and license metadata.
      module RDF
        # Adds RDF license metadata inside a metadata element.
        # @param kwargs [Hash] RDF work options
        # @return [Sevgi::Graphics::Element] metadata element
        def License(**kwargs, &block) = metadata { RDFWork(**kwargs, &block) }

        # Use SPDX license codes in underscored form: https://spdx.org/licenses/
        #
        # Adds Creative Commons BY-SA license metadata.
        # @param kwargs [Hash] RDF work options
        # @return [Sevgi::Graphics::Element] metadata element
        def License_CC_BY_SA(**kwargs, &block)
          License(**kwargs, license: "https://creativecommons.org/licenses/by-sa/4.0/", &block)
        end

        # Adds Creative Commons BY-NC license metadata.
        # @param kwargs [Hash] RDF work options
        # @return [Sevgi::Graphics::Element] metadata element
        def License_CC_BY_NC(**kwargs, &block)
          License(**kwargs, license: "https://creativecommons.org/licenses/by-nc/4.0/", &block)
        end

        # Adds Creative Commons BY-NC-SA license metadata.
        # @param kwargs [Hash] RDF work options
        # @return [Sevgi::Graphics::Element] metadata element
        def License_CC_BY_NC_SA(**kwargs, &block)
          License(**kwargs, license: "https://creativecommons.org/licenses/by-nc-sa/4.0/", &block)
        end

        # Adds Creative Commons BY-ND license metadata.
        # @param kwargs [Hash] RDF work options
        # @return [Sevgi::Graphics::Element] metadata element
        def License_CC_BY_ND(**kwargs, &block)
          License(**kwargs, license: "https://creativecommons.org/licenses/by-nd/4.0/", &block)
        end

        # Adds Creative Commons BY-NC-ND license metadata.
        # @param kwargs [Hash] RDF work options
        # @return [Sevgi::Graphics::Element] metadata element
        def License_CC_BY_NC_ND(**kwargs, &block)
          License(**kwargs, license: "https://creativecommons.org/licenses/by-nc-nd/4.0/", &block)
        end

        # Adds Creative Commons Zero metadata.
        # @param kwargs [Hash] RDF work options
        # @return [Sevgi::Graphics::Element] metadata element
        def License_CC0(**kwargs, &block)
          License(**kwargs, license: "https://creativecommons.org/publicdomain/zero/1.0/", &block)
        end

        # Adds Free Art License metadata.
        # @param kwargs [Hash] RDF work options
        # @return [Sevgi::Graphics::Element] metadata element
        def License_LAL(**kwargs, &block) = License(**kwargs, license: "https://artlibre.org/licence/lal/en/", &block)

        # Builds an RDF root element.
        # @param _kwargs [Hash] currently unused options
        # @return [Sevgi::Graphics::Element] RDF element
        # @raise [Sevgi::ArgumentError] when no block is given
        def RDF(**_kwargs, &block)
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

        # rubocop:disable Metrics/MethodLength
        # Builds a Creative Commons RDF Work element.
        # @param kwargs [Hash] RDF work options
        # @option kwargs [String] :title work title
        # @option kwargs [String] :description work description
        # @option kwargs [String] :creator creator
        # @option kwargs [String] :publisher publisher
        # @option kwargs [String] :date date
        # @option kwargs [String] :language language
        # @option kwargs [String] :license license URL
        # @return [Sevgi::Graphics::Element] RDF element
        def RDFWork(**kwargs, &block)
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
        # rubocop:enable Metrics/MethodLength
      end
    end
  end
end
