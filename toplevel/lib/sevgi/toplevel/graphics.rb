# frozen_string_literal: true

require "sevgi/graphics"

module Sevgi
  # Full-toolkit alias for the callable drawing module contract.
  # Extend a Ruby module with this contract before passing it to callable-module DSL words.
  # @see Sevgi::Graphics::Module
  Module = Graphics::Module

  # Full-toolkit alias for the recursive callable drawing namespace contract.
  # Extend a module with this convenience when its owned module descendants should all become callable drawing modules.
  # @see Sevgi::Graphics::Modules
  Modules = Graphics::Modules

  module Toplevel
    # Builds an SVG document through the full Sevgi top-level DSL.
    # @param document [Symbol, String, Class] document profile name or document class
    # @param canvas [Sevgi::Graphics::Canvas, Sevgi::Graphics::Paper, Symbol, String, Sevgi::Undefined, nil] optional
    #   canvas or paper profile
    # @param attributes [Hash] root SVG attributes
    # @yield the document block evaluated in the SVG document context
    # @yieldreturn [void]
    # @return [Sevgi::Graphics::Document::Proto] SVG document object
    # @raise [Sevgi::ArgumentError] when the document, paper, or canvas arguments are invalid
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
    #   @see Sevgi::Graphics::Mixtures.mixin
    # @overload Mixin(mod, document = Sevgi::Graphics::Document::Base, &block)
    #   Adds a named graphics mixture and an anonymous extension to a document class.
    #   @param mod [Symbol, String] named mixture to mix into the document
    #   @param document [Class] document class receiving the mixture
    #   @yield optional anonymous mixture module body
    #   @yieldreturn [void]
    #   @return [Module] anonymous mixture
    #   @raise [NameError] when a named mixture cannot be resolved
    #   @see Sevgi::Graphics::Mixtures.mixin
    # @overload Mixin(document = Sevgi::Graphics::Document::Base, &block)
    #   Adds an anonymous graphics mixture to a document class.
    #   @param document [Class] document class receiving the mixture
    #   @yield anonymous mixture module body
    #   @yieldreturn [void]
    #   @return [Module] anonymous mixture
    #   @raise [Sevgi::ArgumentError] when no named mixture or block is given
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
    #   @see Sevgi::Graphics#paper!
    def Paper!(...) = Graphics.paper!(...)
  end
end
