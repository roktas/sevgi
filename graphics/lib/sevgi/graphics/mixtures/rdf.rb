# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      module RDF
        def License(**kwargs, &block)             = metadata { RDFWork(**kwargs, &block) }

        # Use SPDX license codes in underscored form: https://spdx.org/licenses/
        #
        # rubocop:disable Layout/LineLength
        def License_CC_BY_SA(**kwargs, &block)    = License(**kwargs, license: "https://creativecommons.org/licenses/by-sa/4.0/", &block)

        def License_CC_BY_NC(**kwargs, &block)    = License(**kwargs, license: "https://creativecommons.org/licenses/by-nc/4.0/", &block)

        def License_CC_BY_NC_SA(**kwargs, &block) = License(**kwargs, license: "https://creativecommons.org/licenses/by-nc-sa/4.0/", &block)

        def License_CC_BY_ND(**kwargs, &block)    = License(**kwargs, license: "https://creativecommons.org/licenses/by-nd/4.0/", &block)

        def License_CC_BY_NC_ND(**kwargs, &block) = License(**kwargs, license: "https://creativecommons.org/licenses/by-nc-nd/4.0/", &block)

        def License_CC0(**kwargs, &block)         = License(**kwargs, license: "https://creativecommons.org/publicdomain/zero/1.0/", &block)

        def License_LAL(**kwargs, &block)         = License(**kwargs, license: "https://artlibre.org/licence/lal/en/", &block)
        # rubocop:enable Layout/LineLength

        def RDF(**kwargs, &block)
          raise(ArgumentError, "Block required") unless block

          Element(
            :"rdf:RDF",
            "xmlns:rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
            "xmlns:dc":  "http://purl.org/dc/elements/1.1/",
            "xmlns:cc":  "http://creativecommons.org/ns#"
          ) do
            Within(&block)
          end
        end

        def RDFWork(**kwargs, &block) # rubocop:disable Metrics/MethodLength
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
