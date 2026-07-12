# frozen_string_literal: true

module Sevgi
  module Graphics
    module Mixtures
      # DSL helpers for including derendered SVG/XML fragments.
      #
      # @!method Include(file, id)
      #   Includes a derendered node matching an id.
      #   SVG/XML content is treated as data and is not evaluated as Ruby source.
      #   @param file [String] source SVG/XML file
      #   @param id [String, Symbol] source node id
      #   @return [Sevgi::Graphics::Element, nil] included element, or nil when it produces no graphics output
      #   @raise [Sevgi::ArgumentError] when the file is absent or XML content is malformed, rootless, or lacks the id
      #   @raise [Sevgi::MissingComponentError] when sevgi/derender is unavailable
      # @!method IncludeChildren(file, id)
      #   Includes the children of a derendered node matching an id.
      #   SVG/XML content is treated as data and is not evaluated as Ruby source.
      #   @param file [String] source SVG/XML file
      #   @param id [String, Symbol] source node id
      #   @return [Array<Sevgi::Graphics::Element>] immutable included-child snapshot
      #   @raise [Sevgi::ArgumentError] when the file is absent or XML content is malformed, rootless, or lacks the id
      #   @raise [Sevgi::MissingComponentError] when sevgi/derender is unavailable
      module Include
        require "sevgi/derender"

        # Includes a derendered node matching an id.
        #
        # SVG/XML file content is treated as data and is not evaluated as Ruby source.
        # @param file [String] source SVG/XML file
        # @param id [String, Symbol] source node id
        # @return [Sevgi::Graphics::Element, nil] included element, or nil when the selected node produces no graphics
        #   output
        # @raise [Sevgi::ArgumentError] when the file cannot be found, file content is malformed or rootless, or the id is
        #   absent
        # @raise [Sevgi::MissingComponentError] when sevgi/derender is unavailable
        def Include(file, id) = Derender.evaluate_file(file, self, id:)

        # Includes the children of a derendered node matching an id.
        #
        # SVG/XML file content is treated as data and is not evaluated as Ruby source.
        # @param file [String] source SVG/XML file
        # @param id [String, Symbol] source node id
        # @return [Array<Sevgi::Graphics::Element>] immutable included-child snapshot
        # @raise [Sevgi::ArgumentError] when the file cannot be found, file content is malformed or rootless, or the id is
        #   absent
        # @raise [Sevgi::MissingComponentError] when sevgi/derender is unavailable
        def IncludeChildren(file, id) = Derender.evaluate_children_file(file, self, id:)
      rescue ::LoadError => e
        raise unless e.path == "sevgi/derender"

        # @overload IncludeChildren(file, id)
        #   Raises because sevgi/derender is unavailable.
        #   @param file [String] source SVG/XML file
        #   @param id [String, Symbol] source node id
        #   @return [void]
        #   @raise [Sevgi::MissingComponentError] always
        def IncludeChildren(...) = MissingComponentError.("sevgi/derender")

        # @overload Include(file, id)
        #   Raises because sevgi/derender is unavailable.
        #   @param file [String] source SVG/XML file
        #   @param id [String, Symbol] source node id
        #   @return [void]
        #   @raise [Sevgi::MissingComponentError] always
        def Include(...) = MissingComponentError.("sevgi/derender")
      end
    end
  end
end
