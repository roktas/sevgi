# frozen_string_literal: true

require_relative "standard/internal"
require_relative "standard/errors"
require_relative "standard/version"

require_relative "standard/data"
require_relative "standard/conform"

module Sevgi
  # The Standard module provides a set of core functionalities and definitions
  # used within the Sevgi ecosystem. It serves as a central point for accessing
  # standard attributes, elements, conformity checks, and model specifications.
  module Standard
    extend self

    # Delegates to `Attribute.set` to define or retrieve standard attributes.
    #
    # @param ... [Object] arguments to be passed to `Attribute.set`.
    # @return [Object] the result of `Attribute.set(...)`.
    def attributes(...)  = Attribute.set(...)

    # Checks if a given attribute name is part of the defined standard attributes.
    #
    # @param name [String, Symbol] the name of the attribute to check.
    # @return [Boolean] true if the attribute is defined, false otherwise.
    def attribute?(name) = Attribute.all.include?(name.to_sym)

    # Delegates to `Conform.` to perform conformity checks.
    #
    # @param ... [Object] arguments to be passed to `Conform.(...)`.
    # @return [Object] the result of `Conform.(...)`.
    def conform(...)     = Conform.(...)

    # Delegates to `Element.set` to define or retrieve standard elements.
    #
    # @param ... [Object] arguments to be passed to `Element.set`.
    # @return [Object] the result of `Element.set(...)`.
    def elements(...)    = Element.set(...)

    # Checks if a given element name is part of the defined standard elements.
    #
    # @param name [String, Symbol] the name of the element to check.
    # @return [Boolean] true if the element is defined, false otherwise.
    def element?(name)   = Element.all.include?(name.to_sym)

    # Delegates to `Specification.model?` to check model specifications.
    #
    # @param ... [Object] arguments to be passed to `Specification.model?(...)`.
    # @return [Boolean] the result of `Specification.model?(...)`.
    def model?(...)      = Specification.model?(...)

    # Retrieves a specification by its name from `Specification`.
    #
    # @param name [String, Symbol] the name of the specification to retrieve.
    # @return [Object, nil] the specification if found, nil otherwise.
    def [](name)         = Specification[name.to_sym]
  end
end
