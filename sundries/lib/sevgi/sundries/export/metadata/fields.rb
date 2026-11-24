# frozen_string_literal: true

module Sevgi
  module Sundries
    module Export
      module Metadata
        # Validates and extracts scalar and collection RDF/XMP fields.
        # @api private
        module Fields
          extend self

          XML_ILLEGAL = /[\x00-\x08\x0b\x0c\x0e-\x1f\uFFFE\uFFFF]/
          MAX_VALUE_BYTES = 1024 * 1024

          # Normalizes and validates caller-supplied PDF metadata fields.
          # @param fields [Hash] metadata fields
          # @return [Hash{Symbol => String, Array<String>}] frozen metadata snapshot
          # @raise [Sevgi::ArgumentError] when any field name or value is invalid
          def capture(fields)
            ArgumentError.("PDF metadata must be a Hash") unless fields.is_a?(Hash)
            unknown = fields.keys - FIELDS
            ArgumentError.("Unknown PDF metadata field: #{unknown.first}") unless unknown.empty?
            fields.to_h { |key, value| [key, capture_field(key, value)] }.freeze
          end

          # Reads one RDF field from root SVG resource nodes.
          # @param resources [Array<Nokogiri::XML::Node>] RDF resource elements
          # @param field [Symbol] field name
          # @return [Array(Symbol, Object), nil]
          # @raise [Sevgi::ArgumentError] when the field is ambiguous or uses unsupported alternatives
          def read(resources, field)
            prefix = field == :license ? "cc" : "dc"
            nodes = resources.flat_map { it.xpath("./#{prefix}:#{field}", NS).to_a }
            ArgumentError.("Ambiguous SVG RDF field: #{field}") if nodes.length > 1
            [field, read_value(nodes.first, field)] unless nodes.empty?
          end

          private

          def capture_field(key, value)
            values = ARRAYS.key?(key) ? Array(value) : [value]
            ArgumentError.("Empty PDF metadata: #{key}") if values.empty?
            captured = values.map { |text| text_value(text, key).freeze }.freeze
            ARRAYS.key?(key) ? captured : captured.first
          end

          def read_value(node, field)
            return node.attribute_with_ns("resource", RDF)&.value || node.text if field == :license

            values = node.xpath("./rdf:Seq/rdf:li | ./rdf:Bag/rdf:li", NS)
            return values.map(&:text) if values.any?

            alternative_text(node, field)
          end

          def alternative_text(node, field)
            alternatives = node.xpath("./rdf:Alt/rdf:li", NS)
            return node.text if alternatives.empty?

            alternate = node.at_xpath("./rdf:Alt/rdf:li[@xml:lang=\"x-default\"]", NS)
            unless alternatives.length == 1 && alternate
              ArgumentError.("SVG RDF #{field} requires one x-default language alternative")
            end

            alternate.text
          end

          def text_value(value, field)
            text = utf8_text(value, field)
            ArgumentError.("Invalid XML text in PDF metadata #{field}") if text.match?(XML_ILLEGAL)

            text.dup
          end

          def utf8_text(value, field)
            unless value.is_a?(String) && value.valid_encoding? && !value.strip.empty?
              ArgumentError.("PDF metadata #{field} must be nonblank text")
            end

            ArgumentError.("PDF metadata #{field} exceeds 1 MiB") if value.bytesize > MAX_VALUE_BYTES
            value.encode(Encoding::UTF_8)
          rescue EncodingError
            ArgumentError.("Invalid text encoding in PDF metadata #{field}")
          end
        end
      end
    end
  end
end
