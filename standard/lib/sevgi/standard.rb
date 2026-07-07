# frozen_string_literal: true

require "sevgi/function"

require_relative "standard/internal"
require_relative "standard/errors"

require_relative "standard/data"
require_relative "standard/conform"

require_relative "standard/version"

module Sevgi
  # SVG standard data and validation helpers.
  module Standard
    extend self

    # @overload attributes(*groups)
    #   Returns SVG attributes, optionally restricted to one or more attribute groups.
    #   @param groups [Array<Symbol>] attribute group names
    #   @return [Set<Symbol>] attribute names
    def attributes(...) = Attribute.set(...)

    # Reports whether an attribute name is recognized by the SVG standard data.
    # @param name [Object] attribute name
    # @return [Boolean]
    def attribute?(name) = name.respond_to?(:to_sym) && Attribute.all.include?(name.to_sym)

    # @overload conform(element, attributes: nil, cdata: nil, elements: nil)
    #   Validates an SVG element usage against the standard data.
    #   @param element [Symbol] SVG element name
    #   @param attributes [Array<Symbol>, nil] attribute names used by the element
    #   @param cdata [String, nil] character data content
    #   @param elements [Array<Symbol>, nil] child element names
    #   @return [Boolean] true when the usage conforms
    #   @raise [Sevgi::ValidationError] when the usage violates the standard data
    #   @raise [Sevgi::PanicError] when the standard data refers to an invalid model
    def conform(...) = Conform.(...)

    # @overload elements(*groups)
    #   Returns SVG elements, optionally restricted to one or more element groups.
    #   @param groups [Array<Symbol>] element group names
    #   @return [Set<Symbol>] element names
    def elements(...) = Element.set(...)

    # Reports whether an element name is recognized by the SVG standard data.
    # @param name [Object] element name
    # @return [Boolean]
    def element?(name) = name.respond_to?(:to_sym) && Element.all.include?(name.to_sym)

    # @overload model?(name, *models)
    #   Checks whether an element uses one of the requested content models.
    #   @param name [Symbol] SVG element name
    #   @param models [Array<Symbol>] model names to match
    #   @return [Boolean]
    def model?(...) = Specification.model?(...)

    # Returns the expanded standard contract for an SVG element.
    # @param name [Object] SVG element name
    # @return [Hash, nil] expanded specification data, or nil when name is invalid or unknown
    def specification(name) = name.respond_to?(:to_sym) ? Specification[name.to_sym] : nil

    alias [] specification
  end
end
