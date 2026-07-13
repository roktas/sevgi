# frozen_string_literal: true

require "sevgi/derender"

module Sevgi
  module Toplevel
    # Converts an SVG/XML file into a derender node.
    # @param file [String] path to the source SVG/XML file
    # @param id [String, nil] optional SVG id selecting a node inside the source
    # @return [Sevgi::Derender::Node] selected node in the derender tree
    # @raise [Sevgi::ArgumentError] when the file is absent, malformed, or rootless, or the id is absent
    # @raise [SystemCallError] when the file cannot be read
    # @see Sevgi::Derender.decompile_file
    def Decompile(file, id = nil) = Derender.decompile_file(file, id:)

    # Converts an SVG/XML file into Sevgi DSL Ruby source.
    # @param file [String] path to the source SVG/XML file
    # @param id [String, nil] optional SVG id selecting a node inside the source
    # @return [String] formatted Sevgi DSL source
    # @raise [Sevgi::ArgumentError] when the file is absent, malformed, or rootless, or the id is absent
    # @raise [Sevgi::PanicError] when generated Ruby source cannot be formatted
    # @raise [SystemCallError] when the file cannot be read
    # @see Sevgi::Derender.derender_file
    def Derender(file, id = nil) = Derender.derender_file(file, id:)
  end
end
