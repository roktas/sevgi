# frozen_string_literal: true

require "sevgi/function"

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

    # Defines or returns a document profile class.
    # @param name [Symbol, String, Sevgi::Undefined] profile name, or Undefined for an anonymous profile
    # @param preambles [Array<String>, nil] document preamble lines
    # @param attributes [Hash] default root attributes
    # @return [Class] document class
    # @raise [Sevgi::ArgumentError] when a named profile conflicts with an existing profile
    def document(name = Undefined, preambles: [], attributes: {})
      Graphics::Document.define(name, preambles:, attributes:)
    end

    # Defines or replaces a document profile class.
    # @param name [Symbol, String] profile name
    # @param preambles [Array<String>, nil] document preamble lines
    # @param attributes [Hash] default root attributes
    # @return [Class] document class
    # @raise [Sevgi::ArgumentError] when the profile name is invalid
    def document!(name, preambles: [], attributes: {})
      Graphics::Document.define(name, preambles:, attributes:, overwrite: true)
    end

    # Defines a paper profile unless the same profile already exists.
    # @param width [Numeric] paper width
    # @param height [Numeric] paper height
    # @param name [Symbol, String] profile name
    # @param unit [Symbol, String] SVG unit
    # @return [Symbol, String] original profile name
    # @raise [Sevgi::ArgumentError] when an existing profile has different dimensions
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
    # @raise [Sevgi::ArgumentError] when the profile name is reserved
    def paper!(width, height, name = :custom, unit: "mm")
      name.tap { Graphics::Paper.define(name, width:, height:, unit:) }
    end

    # Builds an SVG root document.
    # @param document [Symbol, String, Class] document profile name or document class
    # @param canvas [Sevgi::Graphics::Canvas, Sevgi::Graphics::Paper, Symbol, String, Sevgi::Undefined, nil] canvas input
    # @param block [Proc, nil] DSL block evaluated in the root element
    # @return [Sevgi::Graphics::Document::Proto] SVG root element
    # @raise [Sevgi::ArgumentError] when the document or canvas profile is unknown
    def SVG(document = :default, canvas = Undefined, **, &block)
      Graphics::Document.(document, canvas, **, &block)
    end

    extend self
  end

  # Top-level alias for the graphics DSL namespace.
  SVG = Graphics
end
