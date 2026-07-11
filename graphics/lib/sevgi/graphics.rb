# frozen_string_literal: true

require "sevgi/function"

require_relative "graphics/xml"
require_relative "graphics/attribute"
require_relative "graphics/auxiliary"
require_relative "graphics/element"
require_relative "graphics/mixtures"

require_relative "graphics/document"

require_relative "graphics/version"

module Sevgi
  # SVG document builder and DSL namespace.
  module Graphics
    # @overload canvas(arg = Undefined, **kwargs)
    #   Builds a canvas from a paper profile or explicit size.
    #   @param arg [Sevgi::Graphics::Paper, Symbol, String, Sevgi::Undefined] paper profile or paper object
    #   @param kwargs [Hash] canvas keyword arguments
    #   @return [Sevgi::Graphics::Canvas]
    #   @raise [Sevgi::ArgumentError] when the paper profile is unknown
    def canvas(...)
      Graphics::Canvas.from_paper(...)
    end

    # @overload document(name)
    #   Looks up an existing document profile by name.
    #   @param name [Symbol, String] profile name
    #   @return [Class] document class
    #   @raise [Sevgi::ArgumentError] when the profile is unknown
    # @overload document(name, preambles: Undefined, attributes: Undefined)
    #   Looks up a named profile when both definition keywords are omitted. Supplying `preambles:` or `attributes:`
    #   defines a named profile, or returns an existing profile when every explicitly supplied field matches. Omitted
    #   fields are ignored during existing-profile comparison. Profile containers and strings are copied into the
    #   registry; mutable non-container attribute values are stringified once before registration.
    #   @param name [Symbol, String] profile name
    #   @param preambles [Array<String>, nil, Sevgi::Undefined] document preamble lines
    #   @param attributes [Hash, nil, Sevgi::Undefined] default root attributes; nil means an empty Hash
    #   @return [Class] document class
    #   @raise [Sevgi::ArgumentError] when a profile conflicts or metadata is invalid XML, cyclic, or cannot be stringified
    # @overload document(preambles: Undefined, attributes: Undefined)
    #   Defines an anonymous document profile without registering it globally.
    #   @param preambles [Array<String>, nil, Sevgi::Undefined] document preamble lines
    #   @param attributes [Hash, nil, Sevgi::Undefined] default root attributes; nil means an empty Hash
    #   @return [Class] anonymous document class
    #   @raise [Sevgi::ArgumentError] when metadata is invalid XML, cyclic, or cannot be stringified
    # @return [Class] document class
    def document(name = Undefined, preambles: Undefined, attributes: Undefined)
      Graphics::Document.define(name, preambles:, attributes:)
    end

    # Defines or replaces a document profile class.
    # @param name [Symbol, String] profile name
    # @param preambles [Array<String>, nil] document preamble lines
    # Validation and snapshot capture complete before an existing registration is replaced.
    # @param attributes [Hash, nil] default root attributes; nil means an empty Hash
    # @return [Class] document class
    # @raise [Sevgi::ArgumentError] when the name or metadata is invalid XML, cyclic, or cannot be stringified
    def document!(name, preambles: [], attributes: {})
      Graphics::Document.define(name, preambles:, attributes:, overwrite: true)
    end

    # Defines a paper profile unless the same profile already exists.
    # @param width [Numeric] paper width
    # @param height [Numeric] paper height
    # @param name [Symbol, String] profile name
    # @param unit [Symbol, String] SVG unit
    # @return [Symbol, String] original profile name
    # @raise [Sevgi::ArgumentError] when the profile is invalid or an existing profile has different dimensions
    def paper(width, height, name = :custom, unit: "mm")
      profile = Graphics::Paper[width, height, unit, name]

      if Graphics::Paper.exist?(name)
        ArgumentError.("Paper already defined differently: #{name}") unless Graphics::Paper.public_send(name) == profile
      else
        Graphics::Paper.define(name, width:, height:, unit:)
      end

      name
    end

    # Defines or replaces a paper profile.
    # @param width [Numeric] paper width
    # @param height [Numeric] paper height
    # @param name [Symbol, String] profile name
    # @param unit [Symbol, String] SVG unit
    # @return [Symbol, String] original profile name
    # @raise [Sevgi::ArgumentError] when the profile is invalid or the profile name is reserved
    def paper!(width, height, name = :custom, unit: "mm")
      name.tap { Graphics::Paper.define(name, width:, height:, unit:) }
    end

    # Builds an SVG root document.
    # @param document [Symbol, String, Class] document profile name or document class
    # @param canvas [Sevgi::Graphics::Canvas, Sevgi::Graphics::Paper, Symbol, String, Sevgi::Undefined, nil] canvas input
    # @yield evaluates the drawing DSL in the root element
    # @yieldreturn [Object] ignored block result
    # @return [Sevgi::Graphics::Document::Proto] SVG root element
    # @raise [Sevgi::ArgumentError] when the document/canvas profile or root XML attributes are invalid
    def SVG(document = :default, canvas = Undefined, **, &block)
      Graphics::Document.(document, canvas, **, &block)
    end

    extend self
  end

  # Top-level alias for the graphics DSL namespace.
  SVG = Graphics
end
