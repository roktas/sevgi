# frozen_string_literal: true

module Sevgi
  module Sundries
    module Export
      module Metadata
        # Parses metadata XML safely with size and entity restrictions.
        # @api private
        module XML
          extend self

          def parse(source, limit: LIMIT)
            require "nokogiri"

            validate_document(parse_document(source, limit))
          rescue LoadError => e
            raise unless e.path == "nokogiri"

            MissingComponentError.("nokogiri")
          end

          private

          def parse_document(source, limit)
            ArgumentError.("Metadata XML exceeds 16 MiB") if limit && source.bytesize > limit
            ::Nokogiri::XML(source) { |config| config.strict.nonet }
          rescue ::Nokogiri::XML::SyntaxError => e
            ArgumentError.("Invalid metadata XML: #{e.message}")
          end

          def validate_document(document)
            ArgumentError.("Metadata XML cannot declare entities") if document.internal_subset&.entities&.any?
            document
          end
        end

        # Builds and updates XMP packets while preserving unrelated namespaces and resources.
        # @api private
        module Packet
          extend self

          def build(previous, fields)
            xml = XML.parse(previous || BLANK_XMP)
            rdf = xml.at_xpath("//rdf:RDF", NS) || ArgumentError.("PDF XMP must contain RDF")
            update_descriptions(rdf, fields)

            payload = xml.to_xml
            ArgumentError.("PDF XMP exceeds 16 MiB") if payload.bytesize > LIMIT
            payload
          end

          private

          def update_descriptions(rdf, fields)
            descriptions = rdf.xpath("./rdf:Description[not(@rdf:about) or @rdf:about=\"\"]", NS)
            description = descriptions.first || element(rdf, "Description", rdf.namespace)
            rdf_ns = namespace_for(description, "rdf", RDF)
            description["#{rdf_ns.prefix}:about"] = ""

            fields.each do |key, value|
              remove_existing(descriptions, key)
              append(description, key, value, rdf_ns)
            end
          end

          def remove_existing(descriptions, key)
            prefix = key == :license ? "cc" : "dc"
            descriptions.each { it.xpath("./#{prefix}:#{key} | ./@#{prefix}:#{key}", NS).remove }
          end

          def namespace_for(node, default_prefix, uri)
            scopes = node.namespace_scopes
            existing = scopes.find { it.href == uri && it.prefix }
            return existing if existing

            node.add_namespace_definition(unused_prefix(default_prefix, scopes.map(&:prefix)), uri)
          end

          def unused_prefix(preferred, occupied)
            return preferred unless occupied.include?(preferred)

            suffix = (1..).find { !occupied.include?("#{preferred}#{it}") }
            "#{preferred}#{suffix}"
          end

          def append(parent, key, value, rdf_ns)
            ns = key == :license ? namespace_for(parent, "cc", CC) : namespace_for(parent, "dc", DC)
            node = element(parent, key.to_s, ns)
            if key == :license
              node["#{rdf_ns.prefix}:resource"] = value
            else
              append_items(node, key, value, rdf_ns)
            end
          end

          def append_items(node, key, value, rdf_ns)
            container = element(node, ARRAYS.fetch(key, "Alt"), rdf_ns)
            Array(value).each do |text|
              item = element(container, "li", rdf_ns)
              item["xml:lang"] = "x-default" unless ARRAYS.key?(key)
              item.content = text
            end
          end

          def element(parent, name, namespace)
            ::Nokogiri::XML::Node.new(name, parent.document).tap do |node|
              node.namespace = namespace
              parent.add_child(node)
            end
          end
        end
      end
    end
  end
end
