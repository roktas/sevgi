# frozen_string_literal: true

require_relative "derender/internal"

require_relative "derender/attributes"
require_relative "derender/document"
require_relative "derender/elements"
require_relative "derender/evaluator"
require_relative "derender/node"

require_relative "derender/version"

module Sevgi
  # Converts SVG/XML content into Sevgi DSL source or evaluates it into graphics elements.
  #
  # Generated source uses bare DSL calls only for recognized element names that cannot dispatch to an existing Ruby or
  # Sevgi method. Other XML names use the explicit `Element` DSL word so executing generated source preserves the XML
  # tree without invoking same-named Ruby methods.
  #
  # Evaluation APIs treat SVG/XML as data: they build graphics element trees directly and do not execute generated Ruby
  # source. Malformed, rootless, or unmatched input is rejected with {Sevgi::ArgumentError}.
  #
  # Namespace dispatch treats qualified and foreign elements as ordinary XML nodes. Their element identity, namespace
  # declarations, qualified attributes, significant text, and nested `svg` elements survive source generation and direct
  # evaluation. CSS specialization applies only to unqualified `style` elements in no namespace or the default SVG
  # namespace; the document-root strategy additionally requires an unqualified `svg` at the root of the conversion.
  # Simple CSS rules use the readable `css({...})` DSL form. At-rules, duplicate declarations, and other CSS that cannot
  # be represented losslessly as a Hash remain owned raw style content.
  #
  # @example Inspect, select, and convert an immutable result
  #   result = Sevgi::Derender.decompile('<svg><rect id="mark" width="10"/></svg>')
  #   mark = result.find("mark")
  #   mark.attributes #=> {"id"=>"mark", "width"=>"10"}
  #   mark.derender   #=> "rect id: \"mark\", width: 10\n"
  # @example Preserve an at-rule as raw style content
  #   Sevgi::Derender.derender("<style>@media print { rect { fill: black; } }</style>")
  #   #=> "style Sevgi::Graphics::Content.cdata(\"@media print { rect { fill: black; } }\")\n"
  module Derender
    private_constant :Attributes, :Document, :Elements

    # Converts SVG/XML content into an immutable derender result.
    # @param content [String] SVG/XML source content
    # @param id [String, nil] optional SVG id selecting a node inside the source
    # @return [Sevgi::Derender::Node] owned immutable selected node
    # @raise [Sevgi::ArgumentError] when content is malformed or rootless, or when the id is absent
    def self.decompile(content, id: nil) = Document.new(content).decompile(id)

    # Converts an SVG/XML file into an immutable derender result.
    # @param file [String] path to the source SVG/XML file
    # @param id [String, nil] optional SVG id selecting a node inside the source
    # @return [Sevgi::Derender::Node] owned immutable selected node
    # @raise [Sevgi::ArgumentError] when the file cannot be found, file content is malformed or rootless, or the id is
    #   absent
    def self.decompile_file(file, id: nil) = Document.load_file(file).decompile(id)

    # Converts SVG/XML content into Sevgi DSL Ruby source.
    # @param content [String] SVG/XML source content
    # @param id [String, nil] optional SVG id selecting a node inside the source
    # @return [String] formatted Sevgi DSL source
    # @raise [Sevgi::ArgumentError] when content is malformed or rootless, or when the id is absent
    # @raise [Sevgi::PanicError] when generated Ruby source cannot be formatted
    # @note Namespace-aware dispatch preserves ordinary foreign/qualified nodes and nested SVG elements.
    # @note Unsafe bare Ruby names are emitted through the explicit `Element` DSL word.
    def self.derender(content, id: nil) = Document.new(content).decompile(id).derender

    # Converts an SVG/XML file into Sevgi DSL Ruby source.
    # @param file [String] path to the source SVG/XML file
    # @param id [String, nil] optional SVG id selecting a node inside the source
    # @return [String] formatted Sevgi DSL source
    # @raise [Sevgi::ArgumentError] when the file cannot be found, file content is malformed or rootless, or the id is
    #   absent
    # @raise [Sevgi::PanicError] when generated Ruby source cannot be formatted
    # @note Namespace-aware dispatch preserves ordinary foreign/qualified nodes and nested SVG elements.
    # @note Unsafe bare Ruby names are emitted through the explicit `Element` DSL word.
    def self.derender_file(file, id: nil) = Document.load_file(file).decompile(id).derender

    # Evaluates SVG/XML content under a graphics element, including the selected node.
    # @param content [String] SVG/XML source content
    # @param element [Sevgi::Graphics::Element] target graphics element
    # @param id [String, nil] optional SVG id selecting a node inside the source
    # @return [Sevgi::Graphics::Element, nil] included selected/root graphics element, or nil when the selected node
    #   produces no graphics output
    # @raise [Sevgi::ArgumentError] when content is malformed or rootless, or when the id is absent
    # @note Namespace-aware dispatch preserves ordinary foreign/qualified nodes and nested SVG elements.
    def self.evaluate(content, element, id: nil) = Document.new(content).decompile(id).evaluate(element)

    # Evaluates only the selected node's children under a graphics element.
    # @param content [String] SVG/XML source content
    # @param element [Sevgi::Graphics::Element] target graphics element
    # @param id [String, nil] optional SVG id selecting a node inside the source
    # @return [Array<Sevgi::Graphics::Element>] immutable included-child snapshot
    # @raise [Sevgi::ArgumentError] when content is malformed or rootless, or when the id is absent
    # @note Namespace-aware dispatch preserves ordinary foreign/qualified nodes and nested SVG elements.
    def self.evaluate_children(content, element, id: nil)
      Document.new(content).decompile(id).evaluate_children(element)
    end

    # Evaluates an SVG/XML file under a graphics element, including the selected node.
    # @param file [String] path to the source SVG/XML file
    # @param element [Sevgi::Graphics::Element] target graphics element
    # @param id [String, nil] optional SVG id selecting a node inside the source
    # @return [Sevgi::Graphics::Element, nil] included selected/root graphics element, or nil when the selected node
    #   produces no graphics output
    # @raise [Sevgi::ArgumentError] when the file cannot be found, file content is malformed or rootless, or the id is
    #   absent
    # @note Namespace-aware dispatch preserves ordinary foreign/qualified nodes and nested SVG elements.
    def self.evaluate_file(file, element, id: nil) = Document.load_file(file).decompile(id).evaluate(element)

    # Evaluates only the selected node's children from an SVG/XML file under a graphics element.
    # @param file [String] path to the source SVG/XML file
    # @param element [Sevgi::Graphics::Element] target graphics element
    # @param id [String, nil] optional SVG id selecting a node inside the source
    # @return [Array<Sevgi::Graphics::Element>] immutable included-child snapshot
    # @raise [Sevgi::ArgumentError] when the file cannot be found, file content is malformed or rootless, or the id is
    #   absent
    # @note Namespace-aware dispatch preserves ordinary foreign/qualified nodes and nested SVG elements.
    def self.evaluate_children_file(file, element, id: nil)
      Document.load_file(file).decompile(id).evaluate_children(element)
    end
  end
end
