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
  # Evaluation APIs treat SVG/XML as data: they build graphics element trees directly and do not execute generated Ruby
  # source. Malformed, rootless, or unmatched input is rejected with {Sevgi::ArgumentError}.
  module Derender
    # Converts SVG/XML content into a derender node.
    # @param content [String] SVG/XML source content
    # @param id [String, nil] optional SVG id selecting a node inside the source
    # @return [Sevgi::Derender::Node] selected node in the derender tree
    # @raise [Sevgi::ArgumentError] when content is malformed or rootless, or when the id is absent
    def decompile(content, id: nil) = Document.new(content).decompile(id)

    # Converts an SVG/XML file into a derender node.
    # @param file [String] path to the source SVG/XML file
    # @param id [String, nil] optional SVG id selecting a node inside the source
    # @return [Sevgi::Derender::Node] selected node in the derender tree
    # @raise [Sevgi::ArgumentError] when the file cannot be found, file content is malformed or rootless, or the id is
    #   absent
    def decompile_file(file, id: nil) = Document.load_file(file).decompile(id)

    # Converts SVG/XML content into Sevgi DSL Ruby source.
    # @param content [String] SVG/XML source content
    # @param id [String, nil] optional SVG id selecting a node inside the source
    # @return [String] formatted Sevgi DSL source
    # @raise [Sevgi::ArgumentError] when content is malformed or rootless, or when the id is absent
    # @raise [Sevgi::PanicError] when generated Ruby source cannot be formatted
    def derender(content, id: nil) = Document.new(content).decompile(id).derender

    # Converts an SVG/XML file into Sevgi DSL Ruby source.
    # @param file [String] path to the source SVG/XML file
    # @param id [String, nil] optional SVG id selecting a node inside the source
    # @return [String] formatted Sevgi DSL source
    # @raise [Sevgi::ArgumentError] when the file cannot be found, file content is malformed or rootless, or the id is
    #   absent
    # @raise [Sevgi::PanicError] when generated Ruby source cannot be formatted
    def derender_file(file, id: nil) = Document.load_file(file).decompile(id).derender

    # Evaluates SVG/XML content under a graphics element, including the selected node.
    # @param content [String] SVG/XML source content
    # @param element [Sevgi::Graphics::Element] target graphics element
    # @param id [String, nil] optional SVG id selecting a node inside the source
    # @return [Sevgi::Graphics::Element, nil] included selected/root graphics element, or nil when the selected node
    #   produces no graphics output
    # @raise [Sevgi::ArgumentError] when content is malformed or rootless, or when the id is absent
    def evaluate(content, element, id: nil) = Document.new(content).decompile(id).evaluate(element)

    # Evaluates only the selected node's children under a graphics element.
    # @param content [String] SVG/XML source content
    # @param element [Sevgi::Graphics::Element] target graphics element
    # @param id [String, nil] optional SVG id selecting a node inside the source
    # @return [Array<Sevgi::Graphics::Element>] included child graphics elements
    # @raise [Sevgi::ArgumentError] when content is malformed or rootless, or when the id is absent
    def evaluate_children(content, element, id: nil) = Document.new(content).decompile(id).evaluate_children(element)

    # Evaluates an SVG/XML file under a graphics element, including the selected node.
    # @param file [String] path to the source SVG/XML file
    # @param element [Sevgi::Graphics::Element] target graphics element
    # @param id [String, nil] optional SVG id selecting a node inside the source
    # @return [Sevgi::Graphics::Element, nil] included selected/root graphics element, or nil when the selected node
    #   produces no graphics output
    # @raise [Sevgi::ArgumentError] when the file cannot be found, file content is malformed or rootless, or the id is
    #   absent
    def evaluate_file(file, element, id: nil) = Document.load_file(file).decompile(id).evaluate(element)

    # Evaluates only the selected node's children from an SVG/XML file under a graphics element.
    # @param file [String] path to the source SVG/XML file
    # @param element [Sevgi::Graphics::Element] target graphics element
    # @param id [String, nil] optional SVG id selecting a node inside the source
    # @return [Array<Sevgi::Graphics::Element>] included child graphics elements
    # @raise [Sevgi::ArgumentError] when the file cannot be found, file content is malformed or rootless, or the id is
    #   absent
    def evaluate_file_children(file, element, id: nil)
      Document.load_file(file).decompile(id).evaluate_children(element)
    end

    extend self
  end
end
