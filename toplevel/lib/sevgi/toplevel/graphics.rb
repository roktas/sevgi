# frozen_string_literal: true

require "sevgi/graphics"

module Sevgi
  module Toplevel
    # @overload Mixin(mod, document = Sevgi::Graphics::Document::Base, &block)
    #   Adds graphics mixture methods to a document class.
    #   @param mod [Symbol, String] named mixture to mix into the document
    #   @param document [Class] document class receiving the mixture
    #   @yield optional anonymous mixture module body
    #   @yieldreturn [void]
    #   @return [void]
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
    #   @param name [Symbol] paper profile name
    #   @param unit [String, Symbol] size unit
    #   @return [Symbol] the paper profile name
    #   @raise [Sevgi::ArgumentError] when the profile is invalid or an existing profile differs
    #   @see Sevgi::Graphics#paper
    def Paper(...) = Graphics.paper(...)

    # @overload Paper!(width, height, name = :custom, unit: "mm")
    #   Defines or overwrites a named paper profile for DSL use.
    #   @param width [Numeric] paper width
    #   @param height [Numeric] paper height
    #   @param name [Symbol] paper profile name
    #   @param unit [String, Symbol] size unit
    #   @return [Symbol] the paper profile name
    #   @raise [Sevgi::ArgumentError] when the profile is invalid or the paper name is reserved
    #   @see Sevgi::Graphics#paper!
    def Paper!(...) = Graphics.paper!(...)
  end
end
