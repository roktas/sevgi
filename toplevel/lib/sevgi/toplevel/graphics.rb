# frozen_string_literal: true

require "sevgi/graphics"

module Sevgi
  module Toplevel
    # @overload Canvas(paper, **overrides)
    #   Builds a canvas from a paper profile with optional field overrides.
    #   @param paper [Sevgi::Graphics::Paper, Symbol, String] paper object or registered profile
    #   @param overrides [Hash] canvas field overrides
    #   @return [Sevgi::Graphics::Canvas]
    #   @raise [Sevgi::ArgumentError] when the paper or an override is invalid
    # @overload Canvas(width:, height:, unit: "mm", name: :custom, margins: [])
    #   Builds a canvas from an explicit size.
    #   @param width [Numeric] canvas width
    #   @param height [Numeric] canvas height
    #   @param unit [Symbol, String] SVG unit
    #   @param name [Symbol, String] paper name
    #   @param margins [Array<Numeric>] margin shorthand values
    #   @return [Sevgi::Graphics::Canvas]
    #   @raise [Sevgi::ArgumentError] when a required field is omitted or a value is invalid
    # @example Build a paper-backed canvas
    #   canvas = Sevgi.Canvas :a4, margins: [12, 10]
    # @see Sevgi.Canvas
    # @see Sevgi::Graphics.canvas
    def Canvas(...) = Graphics.canvas(...)

    # @overload Document(name)
    #   Looks up an existing document profile by name.
    #   @param name [Symbol, String] profile name
    #   @return [Class] document class
    #   @raise [Sevgi::ArgumentError] when the profile is unknown
    # @overload Document(name, preambles: Undefined, attributes: Undefined)
    #   Defines or validates a named document profile.
    #   @param name [Symbol, String] profile name
    #   @param preambles [Array<String>, nil, Sevgi::Undefined] document preamble lines
    #   @param attributes [Hash, nil, Sevgi::Undefined] default root attributes
    #   @return [Class] document class
    #   @raise [Sevgi::ArgumentError] when a profile conflicts or metadata is invalid
    # @overload Document(preambles: Undefined, attributes: Undefined)
    #   Defines an anonymous document profile without registering it globally.
    #   @param preambles [Array<String>, nil, Sevgi::Undefined] document preamble lines
    #   @param attributes [Hash, nil, Sevgi::Undefined] default root attributes
    #   @return [Class] anonymous document class
    #   @raise [Sevgi::ArgumentError] when metadata is invalid
    # @return [Class] document class
    # @example Define and use a document profile
    #   Sevgi.Document :icon, attributes: {viewBox: "0 0 24 24"}
    #   drawing = Sevgi.SVG(:icon) { circle cx: 12, cy: 12, r: 10 }
    # @see Sevgi.Document
    # @see Sevgi::Graphics.document
    def Document(...) = Graphics.document(...)

    # Defines or replaces a document profile.
    # @param name [Symbol, String] profile name
    # @param preambles [Array<String>, nil] document preamble lines
    # @param attributes [Hash, nil] default root attributes
    # @return [Class] document class
    # @raise [Sevgi::ArgumentError] when the name or metadata is invalid
    # @see Sevgi.Document!
    # @see Sevgi::Graphics.document!
    def Document!(name, preambles: [], attributes: {})
      Graphics.document!(name, preambles:, attributes:)
    end

    # Builds an SVG document through the full Sevgi top-level DSL.
    # @param document [Symbol, String, Class] document profile name or document class
    # @param canvas [Sevgi::Graphics::Canvas, Sevgi::Graphics::Paper, Symbol, String, Sevgi::Undefined, nil] optional
    #   canvas or paper profile
    # @param attributes [Hash] root SVG attributes
    # @yield the document block evaluated in the SVG document context
    # @yieldreturn [void]
    # @return [Sevgi::Graphics::Document::Proto] SVG document object
    # @raise [Sevgi::ArgumentError] when the document, paper, or canvas arguments are invalid
    # @see Sevgi.SVG
    # @see Sevgi::Graphics.SVG
    def SVG(document = :default, canvas = Undefined, **attributes, &block)
      Graphics.SVG(document, canvas, **attributes, &block)
    end

    # @overload Mixin(mod, document = Sevgi::Graphics::Document::Base)
    #   Adds a named graphics mixture to a document class.
    #   @param mod [Symbol, String] named mixture to mix into the document
    #   @param document [Class] document class receiving the mixture
    #   @return [nil]
    #   @raise [NameError] when a named mixture cannot be resolved
    #   @see Sevgi.Mixin
    #   @see Sevgi::Graphics::Mixtures.mixin
    # @overload Mixin(mod, document = Sevgi::Graphics::Document::Base, &block)
    #   Adds a named graphics mixture and an anonymous extension to a document class.
    #   @param mod [Symbol, String] named mixture to mix into the document
    #   @param document [Class] document class receiving the mixture
    #   @yield optional anonymous mixture module body
    #   @yieldreturn [void]
    #   @return [Module] anonymous mixture
    #   @raise [NameError] when a named mixture cannot be resolved
    #   @see Sevgi.Mixin
    #   @see Sevgi::Graphics::Mixtures.mixin
    # @overload Mixin(document = Sevgi::Graphics::Document::Base, &block)
    #   Adds an anonymous graphics mixture to a document class.
    #   @param document [Class] document class receiving the mixture
    #   @yield anonymous mixture module body
    #   @yieldreturn [void]
    #   @return [Module] anonymous mixture
    #   @raise [Sevgi::ArgumentError] when no named mixture or block is given
    #   @see Sevgi.Mixin
    #   @see Sevgi::Graphics::Mixtures.mixin
    def Mixin(...) = Graphics::Mixtures.mixin(...)

    # @overload Paper(width, height, name = :custom, unit: "mm")
    #   Defines or validates a named paper profile for DSL use.
    #   @param width [Numeric] paper width
    #   @param height [Numeric] paper height
    #   @param name [Symbol, String] paper profile name
    #   @param unit [String, Symbol] size unit
    #   @return [Symbol, String] the original paper profile name
    #   @raise [Sevgi::ArgumentError] when the profile is invalid or an existing profile differs
    #   @see Sevgi.Paper
    #   @see Sevgi::Graphics#paper
    def Paper(...) = Graphics.paper(...)

    # @overload Paper!(width, height, name = :custom, unit: "mm")
    #   Defines or overwrites a named paper profile for DSL use.
    #   @param width [Numeric] paper width
    #   @param height [Numeric] paper height
    #   @param name [Symbol, String] paper profile name
    #   @param unit [String, Symbol] size unit
    #   @return [Symbol, String] the original paper profile name
    #   @raise [Sevgi::ArgumentError] when the profile is invalid or the paper name is reserved
    #   @see Sevgi.Paper!
    #   @see Sevgi::Graphics#paper!
    def Paper!(...) = Graphics.paper!(...)
  end
end
