# frozen_string_literal: true

require "fileutils"
require "tempfile"

module Sevgi
  module Sundries
    module Export
      # Converts document RDF to PDF XMP without changing page content or adding dates.
      # @api private
      # rubocop:disable-next Metrics/ModuleLength
      module Metadata
        DC = "http://purl.org/dc/elements/1.1/"
        RDF = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
        CC = "http://creativecommons.org/ns#"
        NS = {"svg" => "http://www.w3.org/2000/svg", "rdf" => RDF, "dc" => DC, "cc" => CC}.freeze
        FIELDS = %i[title description creator publisher date language license rights].freeze
        ARRAYS = {creator: "Seq", publisher: "Bag", date: "Seq", language: "Bag"}.freeze
        LIMIT = 16 * 1024 * 1024
        private_constant :DC, :RDF, :CC, :NS, :FIELDS, :ARRAYS, :LIMIT

        # XML admission and serialization share the field and namespace contract here.
        # rubocop:disable-next Metrics/ClassLength
        class << self
          # Captures the same scalar/list field contract used by both authoring paths.
          # rubocop:disable-next Metrics/AbcSize, Metrics/CyclomaticComplexity
          def capture(fields)
            ArgumentError.("PDF metadata must be a Hash") unless fields.is_a?(Hash)
            unknown = fields.keys - FIELDS
            ArgumentError.("Unknown PDF metadata field: #{unknown.first}") unless unknown.empty?
            fields.to_h do |key, value|
              values = ARRAYS.key?(key) ? Array(value) : [value]
              ArgumentError.("Empty PDF metadata: #{key}") if values.empty?
              values = values.map { |text| text_value(text, key).freeze }.freeze
              [key, ARRAYS.key?(key) ? values : values.first]
            end.freeze
          end

          def from_svg(svg)
            return {}.freeze unless svg.include?("metadata")
            document = parse(svg, limit: nil)
            resources = document.xpath("/svg:svg/svg:metadata/rdf:RDF/*", NS).select do |node|
              ["", nil].include?(node.attribute_with_ns("about", RDF)&.value)
            end
            capture(FIELDS.filter_map { |field| read(resources, field) }.to_h)
          end

          def export(output, fields)
            parent = File.dirname(output)
            parent = File.dirname(parent) until File.directory?(parent)
            Tempfile.create([".sevgi-xmp-", ".pdf"], parent) do |temporary|
              temporary.close
              yield temporary.path
              write(temporary.path, fields)
              FileUtils.mkdir_p(File.dirname(output))
              File.rename(temporary.path, output)
            end
            output
          end

          # Staging keeps parser and write failures from replacing the caller's PDF.
          # rubocop:disable-next Metrics/AbcSize, Metrics/MethodLength
          def write(path, fields)
            require "hexapdf"
            document = HexaPDF::Document.open(path)
            payload = packet(document.catalog[:Metadata]&.stream, fields)
            document.catalog[:Metadata] = document.add({Type: :Metadata, Subtype: :XML}, stream: payload)
            {title: :Title, description: :Subject, creator: :Author}.each do |key, entry|
              next unless fields.key?(key)
              document.trailer[:Info] ||= {}
              document.trailer[:Info][entry] = Array(fields.fetch(key)).join("; ")
            end
            Tempfile.create([".sevgi-xmp-", ".pdf"], File.dirname(path)) do |temporary|
              temporary.close
              document.write(temporary.path, validate: false, update_fields: false)
              File.rename(temporary.path, path)
            end
          rescue LoadError => e
            raise unless e.path == "hexapdf"
            MissingComponentError.("hexapdf")
          rescue HexaPDF::Error => e
            ExportError.("PDF metadata error: #{e.message}")
          end

          private

          def read(resources, field)
            prefix = field == :license ? "cc" : "dc"
            nodes = resources.flat_map { it.xpath("./#{prefix}:#{field}", NS).to_a }
            ArgumentError.("Ambiguous SVG RDF field: #{field}") if nodes.length > 1
            [field, read_value(nodes.first, field)] unless nodes.empty?
          end

          # Accepts literal RDF and its XMP containers without flattening language alternatives.
          # rubocop:disable-next Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          def read_value(node, field)
            return node.attribute_with_ns("resource", RDF)&.value || node.text if field == :license
            values = node.xpath("./rdf:Seq/rdf:li | ./rdf:Bag/rdf:li", NS)
            return values.map(&:text) if values.any?
            alternatives = node.xpath("./rdf:Alt/rdf:li", NS)
            return node.text if alternatives.empty?
            alternate = node.at_xpath('./rdf:Alt/rdf:li[@xml:lang="x-default"]', NS)
            unless alternatives.length == 1 && alternate
              ArgumentError.("SVG RDF #{field} requires one x-default language alternative")
            end
            alternate.text
          end

          # Keep unrelated XMP namespaces and resources when replacing document properties.
          # rubocop:disable-next Metrics/AbcSize, Metrics/MethodLength
          def packet(previous, fields)
            xml = parse(previous || '<x:xmpmeta xmlns:x="adobe:ns:meta/"><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/></x:xmpmeta>')
            rdf = xml.at_xpath("//rdf:RDF", NS)
            ArgumentError.("PDF XMP must contain RDF") unless rdf
            descriptions = rdf.xpath('./rdf:Description[not(@rdf:about) or @rdf:about=""]', NS)
            description = descriptions.first || element(rdf, "Description", rdf.namespace)
            description["rdf:about"] = ""
            description.add_namespace_definition("dc", DC)
            description.add_namespace_definition("cc", CC)
            fields.each do |key, value|
              prefix = key == :license ? "cc" : "dc"
              descriptions.each { it.xpath("./#{prefix}:#{key} | ./@#{prefix}:#{key}", NS).remove }
              append(description, key, value)
            end
            payload = xml.to_xml
            ArgumentError.("PDF XMP exceeds 16 MiB") if payload.bytesize > LIMIT
            payload
          end

          def text_value(value, field)
            ArgumentError.("PDF metadata #{field} must be nonblank text") unless value.is_a?(String) && value.valid_encoding? && !value.strip.empty?
            ArgumentError.("PDF metadata #{field} exceeds 1 MiB") if value.bytesize > 1024 * 1024
            text = value.encode(Encoding::UTF_8)
            ArgumentError.("Invalid XML text in PDF metadata #{field}") if text.match?(/[\x00-\x08\x0b\x0c\x0e-\x1f\uFFFE\uFFFF]/)
            text.dup
          rescue EncodingError
            ArgumentError.("Invalid text encoding in PDF metadata #{field}")
          end

          # The source SVG can be large; only XMP packets have this size limit.
          # rubocop:disable-next Metrics/AbcSize, Metrics/CyclomaticComplexity
          def parse(source, limit: LIMIT)
            require "nokogiri"
            ArgumentError.("Metadata XML exceeds 16 MiB") if limit && source.bytesize > limit
            document = Nokogiri::XML(source) { |config| config.strict.nonet }
            ArgumentError.("Metadata XML cannot declare entities") if document.internal_subset&.entities&.any?
            document
          rescue LoadError => e
            raise unless e.path == "nokogiri"
            MissingComponentError.("nokogiri")
          rescue Nokogiri::XML::SyntaxError => e
            ArgumentError.("Invalid metadata XML: #{e.message}")
          end

          # XMP types differ from RDF literals: names use arrays and text uses language alternatives.
          # rubocop:disable-next Metrics/AbcSize, Metrics/MethodLength
          def append(parent, key, value)
            prefix = key == :license ? "cc" : "dc"
            node = element(parent, key.to_s, parent.namespace_definitions.find { it.prefix == prefix })
            if key == :license
              node["rdf:resource"] = value
              return
            end
            container = element(node, ARRAYS.fetch(key, "Alt"), parent.namespace)
            Array(value).each do |text|
              item = element(container, "li", parent.namespace)
              item["xml:lang"] = "x-default" unless ARRAYS.key?(key)
              item.content = text
            end
          end

          def element(parent, name, namespace)
            Nokogiri::XML::Node.new(name, parent.document).tap do |node|
              node.namespace = namespace
              parent.add_child(node)
            end
          end
        end
      end

      private_constant :Metadata
    end
  end
end
