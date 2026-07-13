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
  #
  # @example Build and render a minimal SVG document
  #   drawing = Sevgi::Graphics.SVG(:minimal, width: 10, height: 10) do
  #     circle cx: 5, cy: 5, r: 4
  #   end
  #   drawing.Render #=> "<svg ...>...</svg>\n"
  # @see https://sevgi.roktas.dev/showcase/ Runnable drawing examples
  module Graphics
    # @overload canvas(paper, **overrides)
    #   Builds a canvas from a paper profile with optional field overrides.
    #   @param paper [Sevgi::Graphics::Paper, Symbol, String] paper object or registered profile
    #   @param overrides [Hash] canvas field overrides
    #   @return [Sevgi::Graphics::Canvas]
    #   @raise [Sevgi::ArgumentError] when the paper or an override is invalid
    # @overload canvas(width:, height:, unit: "mm", name: :custom, margins: [])
    #   Builds a canvas from an explicit size.
    #   @param width [Numeric] canvas width
    #   @param height [Numeric] canvas height
    #   @param unit [Symbol, String] SVG unit
    #   @param name [Symbol, String] paper name
    #   @param margins [Array<Numeric>] margin shorthand values
    #   @return [Sevgi::Graphics::Canvas]
    #   @raise [Sevgi::ArgumentError] when a required field is omitted or a value is invalid
    def canvas(...)
      Graphics::Canvas.call(...)
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
    #   process-global, thread-atomic registry; attribute names and nested Hash keys are normalized, nil attributes are
    #   omitted, update suffixes are retained for document-class inheritance, and mutable non-container values are
    #   stringified once before registration. Concurrent identical definitions return the same canonical registered
    #   class.
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
    # @example Define, look up, and inspect a named document
    #   document(:card, attributes: {viewBox: "0 0 100 60"})
    #   Document.fetch(:card)             # => the registered document class
    #   Document.profile(:card).attributes # => {viewBox: "0 0 100 60"}
    # @example Define an anonymous document without changing the registry
    #   klass = document(attributes: {viewBox: "0 0 10 10"})
    #   klass.profile.name # => nil
    def document(name = Undefined, preambles: Undefined, attributes: Undefined)
      Graphics::Document.define(name, preambles:, attributes:)
    end

    # Defines or replaces a document profile class.
    # Validation and snapshot capture complete before an existing registration is atomically replaced.
    # @param name [Symbol, String] profile name
    # @param preambles [Array<String>, nil] document preamble lines
    # @param attributes [Hash, nil] default root attributes; nil means an empty Hash
    # @return [Class] document class
    # @raise [Sevgi::ArgumentError] when the name or metadata is invalid XML, cyclic, or cannot be stringified
    def document!(name, preambles: [], attributes: {})
      Graphics::Document.define(name, preambles:, attributes:, overwrite: true)
    end

    # Defines a paper profile unless the same profile already exists. Registration is process-global and thread-atomic;
    # an identical concurrent definition is idempotent and a conflicting definition is rejected.
    # @param width [Numeric] paper width
    # @param height [Numeric] paper height
    # @param name [Symbol, String] profile name
    # @param unit [Symbol, String] SVG unit
    # @return [Symbol, String] original profile name
    # @raise [Sevgi::ArgumentError] when the profile is invalid or an existing profile has different dimensions
    def paper(width, height, name = :custom, unit: "mm")
      Graphics::Paper.define(name, width:, height:, unit:, overwrite: false)

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
      name.tap { Graphics::Paper.define(name, width:, height:, unit:, overwrite: true) }
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
