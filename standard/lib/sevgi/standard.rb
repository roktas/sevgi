# frozen_string_literal: true

require "sevgi/function"

require_relative "standard/internal"
require_relative "standard/errors"

require_relative "standard/data"
require_relative "standard/conform"

require_relative "standard/version"

module Sevgi
  # SVG standard data and validation helpers.
  # The registry is a Sevgi compatibility set based on SVG 2 plus the split-out SVG modules and legacy entries already
  # modeled in the bundled specifications. Supported element names must have matching specification data; abandoned or
  # unspecified proposal entries are not exposed as supported elements.
  #
  # @example Validate an SVG element usage
  #   Sevgi::Standard.conform(:rect, attributes: %i[width height]) #=> true
  #   Sevgi::Standard.element?(:foreignObject)                    #=> true
  module Standard
    extend self

    # @overload attributes(*groups)
    #   Returns SVG attributes, optionally restricted to one or more attribute groups.
    #   @param groups [Array<String, Symbol>] attribute group names
    #   @return [Set<Symbol>] mutation-isolated attribute-name snapshot
    def attributes(...) = Attribute.set(...)

    # Reports whether an attribute name is recognized by the SVG standard data.
    # @param name [String, Symbol] attribute name
    # @return [Boolean]
    # @raise [Sevgi::ArgumentError] when name is not a String or Symbol
    # @raise [Sevgi::ArgumentError] when name is not a valid SVG-style name
    def attribute?(name) = Attribute.all.include?(Name.normalize!(name, context: "attribute"))

    # @overload conform(element, attributes: nil, cdata: nil, elements: nil)
    #   Validates an SVG element usage against the standard data.
    #   @param element [String, Symbol] SVG element name
    #   @param attributes [Array<String, Symbol>, String, Symbol, nil] attribute names used by the element
    #   @param cdata [String, nil] character data content
    #   @param elements [Array<String, Symbol>, String, Symbol, nil] child element names
    #   @return [Boolean] true when the usage conforms
    #   @raise [Sevgi::ArgumentError] when any name is not a String or Symbol
    #   @raise [Sevgi::ArgumentError] when any name is not a valid SVG-style name
    #   @raise [Sevgi::ArgumentError] when cdata is not a String or nil
    #   @raise [Sevgi::ValidationError] when the usage violates the standard data
    #   @raise [Sevgi::PanicError] when the standard data refers to an invalid model
    #   @note Empty character data is treated as absent.
    def conform(...) = Conform.(...)

    # @overload elements(*groups)
    #   Returns SVG elements, optionally restricted to one or more element groups.
    #   @param groups [Array<String, Symbol>] element group names
    #   @return [Set<Symbol>] mutation-isolated element-name snapshot
    def elements(...) = Element.set(...)

    # Reports whether an element name is recognized by the SVG standard data.
    # @param name [String, Symbol] element name
    # @return [Boolean]
    # @raise [Sevgi::ArgumentError] when name is not a String or Symbol
    # @raise [Sevgi::ArgumentError] when name is not a valid SVG-style name
    def element?(name) = Element.all.include?(Name.normalize!(name, context: "element"))

    # @overload model?(name, *models)
    #   Checks whether an element uses one of the requested content models.
    #   @param name [String, Symbol] SVG element name
    #   @param models [Array<String, Symbol>] model names to match
    #   @return [Boolean]
    #   @raise [Sevgi::ArgumentError] when any name is not a String or Symbol
    #   @raise [Sevgi::ArgumentError] when any name is not a valid SVG-style name
    def model?(...) = Specification.model?(...)

    # Returns the expanded standard contract for an SVG element.
    # The returned hash and nested arrays are mutation-isolated snapshots; changing them does not alter the registry.
    # @param name [String, Symbol] SVG element name
    # @return [Hash, nil] expanded specification snapshot, or nil when name is unknown
    # @raise [Sevgi::ArgumentError] when name is not a String or Symbol
    # @raise [Sevgi::ArgumentError] when name is not a valid SVG-style name
    def specification(name) = Specification[Name.normalize!(name, context: "element")]

    alias [] specification
  end
end
