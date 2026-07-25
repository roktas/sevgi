# frozen_string_literal: true

require "sevgi/derender"

module Sevgi
  module Toplevel
    # Converts inline SVG/XML content into a derender node.
    # @param content [String] SVG/XML source content
    # @param id [String, Symbol, nil] optional SVG id selecting a node inside the source
    # @param omit [String, Symbol, Array<String, Symbol>, nil] exact attribute name or names omitted from the selected
    #   subtree after id selection
    # @return [Sevgi::Derender::Node] selected node in the derender tree
    # @raise [Sevgi::ArgumentError] when content is malformed or rootless, or the id is absent
    # @see Sevgi.Decompile
    # @see Sevgi::Derender.decompile
    def Decompile(content, id: nil, omit: nil) = Derender.decompile(content, id:, omit:)

    # Converts an SVG/XML file into a derender node.
    # @param file [String] path to the source SVG/XML file
    # @param id [String, Symbol, nil] optional SVG id selecting a node inside the source
    # @param omit [String, Symbol, Array<String, Symbol>, nil] exact attribute name or names omitted from the selected
    #   subtree after id selection
    # @return [Sevgi::Derender::Node] selected node in the derender tree
    # @raise [Sevgi::ArgumentError] when the file is absent, malformed, or rootless, or the id is absent
    # @raise [SystemCallError] when the file cannot be read
    # @see Sevgi.DecompileFile
    # @see Sevgi::Derender.decompile_file
    def DecompileFile(file, id: nil, omit: nil) = Derender.decompile_file(file, id:, omit:)

    # Converts inline SVG/XML content into Sevgi DSL Ruby source.
    # @param content [String] SVG/XML source content
    # @param id [String, Symbol, nil] optional SVG id selecting a node inside the source
    # @param omit [String, Symbol, Array<String, Symbol>, nil] exact attribute name or names omitted from the selected
    #   subtree after id selection
    # @return [String] formatted Sevgi DSL source
    # @raise [Sevgi::ArgumentError] when content is malformed or rootless, or the id is absent
    # @raise [Sevgi::PanicError] when generated Ruby source cannot be formatted
    # @see Sevgi.Derender
    # @see Sevgi::Derender.derender
    def Derender(content, id: nil, omit: nil) = Derender.derender(content, id:, omit:)

    # Converts an SVG/XML file into Sevgi DSL Ruby source.
    # @param file [String] path to the source SVG/XML file
    # @param id [String, Symbol, nil] optional SVG id selecting a node inside the source
    # @param omit [String, Symbol, Array<String, Symbol>, nil] exact attribute name or names omitted from the selected
    #   subtree after id selection
    # @return [String] formatted Sevgi DSL source
    # @raise [Sevgi::ArgumentError] when the file is absent, malformed, or rootless, or the id is absent
    # @raise [Sevgi::PanicError] when generated Ruby source cannot be formatted
    # @raise [SystemCallError] when the file cannot be read
    # @see Sevgi.DerenderFile
    # @see Sevgi::Derender.derender_file
    def DerenderFile(file, id: nil, omit: nil) = Derender.derender_file(file, id:, omit:)

    # Evaluates inline SVG/XML content under a graphics element, including the selected node.
    # @param content [String] SVG/XML source content
    # @param element [Sevgi::Graphics::Element] target graphics element
    # @param id [String, Symbol, nil] optional SVG id selecting a node inside the source
    # @param omit [String, Symbol, Array<String, Symbol>, nil] exact attribute name or names omitted from the selected
    #   subtree after id selection
    # @return [Sevgi::Graphics::Element, nil] included selected/root element, or nil when it produces no output
    # @raise [Sevgi::ArgumentError] when content is malformed or rootless, or the id is absent
    # @see Sevgi.Evaluate
    # @see Sevgi::Derender.evaluate
    def Evaluate(content, element, id: nil, omit: nil) = Derender.evaluate(content, element, id:, omit:)

    # Evaluates only the selected node's children from inline SVG/XML content under a graphics element.
    # @param content [String] SVG/XML source content
    # @param element [Sevgi::Graphics::Element] target graphics element
    # @param id [String, Symbol, nil] optional SVG id selecting a node inside the source
    # @param omit [String, Symbol, Array<String, Symbol>, nil] exact attribute name or names omitted from the selected
    #   subtree after id selection
    # @return [Array<Sevgi::Graphics::Element>] immutable included-child snapshot
    # @raise [Sevgi::ArgumentError] when content is malformed or rootless, or the id is absent
    # @see Sevgi.EvaluateChildren
    # @see Sevgi::Derender.evaluate_children
    def EvaluateChildren(content, element, id: nil, omit: nil)
      Derender.evaluate_children(content, element, id:, omit:)
    end

    # Evaluates only the selected node's children from an SVG/XML file under a graphics element.
    # @param file [String] path to the source SVG/XML file
    # @param element [Sevgi::Graphics::Element] target graphics element
    # @param id [String, Symbol, nil] optional SVG id selecting a node inside the source
    # @param omit [String, Symbol, Array<String, Symbol>, nil] exact attribute name or names omitted from the selected
    #   subtree after id selection
    # @return [Array<Sevgi::Graphics::Element>] immutable included-child snapshot
    # @raise [Sevgi::ArgumentError] when the file is absent, malformed, or rootless, or the id is absent
    # @raise [SystemCallError] when the file cannot be read
    # @see Sevgi.EvaluateChildrenFile
    # @see Sevgi::Derender.evaluate_children_file
    def EvaluateChildrenFile(file, element, id: nil, omit: nil)
      Derender.evaluate_children_file(file, element, id:, omit:)
    end

    # Evaluates an SVG/XML file under a graphics element, including the selected node.
    # @param file [String] path to the source SVG/XML file
    # @param element [Sevgi::Graphics::Element] target graphics element
    # @param id [String, Symbol, nil] optional SVG id selecting a node inside the source
    # @param omit [String, Symbol, Array<String, Symbol>, nil] exact attribute name or names omitted from the selected
    #   subtree after id selection
    # @return [Sevgi::Graphics::Element, nil] included selected/root element, or nil when it produces no output
    # @raise [Sevgi::ArgumentError] when the file is absent, malformed, or rootless, or the id is absent
    # @raise [SystemCallError] when the file cannot be read
    # @see Sevgi.EvaluateFile
    # @see Sevgi::Derender.evaluate_file
    def EvaluateFile(file, element, id: nil, omit: nil) = Derender.evaluate_file(file, element, id:, omit:)
  end
end
