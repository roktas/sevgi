# frozen_string_literal: true

module Sevgi
  # Public SVG facade installed by `require "sevgi"`.
  #
  # Capitalized methods are SVG DSL operations: {SVG.Canvas} creates a canvas,
  # {SVG.Document} defines a document profile, and {SVG.Paper} registers a
  # paper size. Double-colon names are Ruby constants and types, such as
  # {SVG::Canvas} and {SVG::Document}. The global `SVG(...)` method builds a
  # drawing; there is intentionally no stuttering `SVG.SVG(...)` form.
  #
  # Lowercase constructors remain on {Sevgi::Graphics} for focused component
  # use. Script execution belongs to {Sevgi.execute} and is not part of this
  # SVG-domain facade.
  #
  # @example Compose a drawing through the facade
  #   SVG.Paper 85, 55, :card
  #   canvas = SVG.Canvas :card, margins: 4
  #   profile = SVG.Document attributes: {viewBox: "0 0 85 55"}
  #
  #   drawing = SVG profile, canvas do
  #     rect width: 85, height: 55, rx: 3
  #   end
  #
  #   drawing.Render
  # @example Distinguish an operation from its result type
  #   canvas = SVG.Canvas width: 24, height: 24, unit: :px
  #   canvas.is_a?(SVG::Canvas) #=> true
  # @see https://sevgi.roktas.dev/getting-started/ Getting started
  # @see https://sevgi.roktas.dev/library-mode/ Library mode guide
  module SVG
    Attributes = Graphics::Attributes
    Canvas = Graphics::Canvas
    Content = Graphics::Content
    Document = Graphics::Document
    Element = Graphics::Element
    LintError = Graphics::LintError
    Margin = Graphics::Margin
    Mixtures = Graphics::Mixtures
    Module = Graphics::Module
    Modules = Graphics::Modules
    Paper = Graphics::Paper
    VERSION = Sevgi::VERSION

    # Builds a canvas from a paper profile or explicit dimensions.
    # @return [Sevgi::Graphics::Canvas] canvas value
    # @see Sevgi::Toplevel#Canvas
    def self.Canvas(...) = Sevgi.Canvas(...)

    # Converts inline SVG/XML into an immutable Derender node.
    # @return [Sevgi::Derender::Node] selected node
    # @see Sevgi::Toplevel#Decompile
    def self.Decompile(...) = Sevgi.Decompile(...)

    # Converts an SVG/XML file into an immutable Derender node.
    # @return [Sevgi::Derender::Node] selected node
    # @see Sevgi::Toplevel#DecompileFile
    def self.DecompileFile(...) = Sevgi.DecompileFile(...)

    # Converts inline SVG/XML into formatted Sevgi DSL source.
    # @return [String] formatted Sevgi DSL source
    # @see Sevgi::Toplevel#Derender
    def self.Derender(...) = Sevgi.Derender(...)

    # Converts an SVG/XML file into formatted Sevgi DSL source.
    # @return [String] formatted Sevgi DSL source
    # @see Sevgi::Toplevel#DerenderFile
    def self.DerenderFile(...) = Sevgi.DerenderFile(...)

    # Defines, validates, or looks up a document profile.
    # @return [Class] document class
    # @see Sevgi::Toplevel#Document
    def self.Document(...) = Sevgi.Document(...)

    # Defines or replaces a document profile.
    # @return [Class] document class
    # @see Sevgi::Toplevel#Document!
    def self.Document!(...) = Sevgi.Document!(...)

    # Includes an inline SVG/XML node under a graphics element.
    # @return [Sevgi::Graphics::Element, nil] included element, or nil when no output is produced
    # @see Sevgi::Toplevel#Evaluate
    def self.Evaluate(...) = Sevgi.Evaluate(...)

    # Includes only an inline SVG/XML node's children under a graphics element.
    # @return [Array<Sevgi::Graphics::Element>] immutable included-child snapshot
    # @see Sevgi::Toplevel#EvaluateChildren
    def self.EvaluateChildren(...) = Sevgi.EvaluateChildren(...)

    # Includes only an SVG/XML file node's children under a graphics element.
    # @return [Array<Sevgi::Graphics::Element>] immutable included-child snapshot
    # @see Sevgi::Toplevel#EvaluateChildrenFile
    def self.EvaluateChildrenFile(...) = Sevgi.EvaluateChildrenFile(...)

    # Includes an SVG/XML file node under a graphics element.
    # @return [Sevgi::Graphics::Element, nil] included element, or nil when no output is produced
    # @see Sevgi::Toplevel#EvaluateFile
    def self.EvaluateFile(...) = Sevgi.EvaluateFile(...)

    # Fits a drawable grid to a graphics canvas.
    # @return [Sevgi::Sundries::Grid] fitted grid
    # @see Sevgi::Toplevel#Grid
    def self.Grid(...) = Sevgi.Grid(...)

    # Loads nested `.sevgi` files through the active executor scope.
    # @return [Array<String>] requested file names
    # @see Sevgi::Toplevel#Load
    def self.Load(...) = Sevgi.Load(...)

    # Extends a document profile with a named or anonymous graphics mixture.
    # @return [Module, nil] anonymous mixture when supplied, otherwise nil
    # @see Sevgi::Toplevel#Mixin
    def self.Mixin(...) = Sevgi.Mixin(...)

    # Defines or validates a named paper profile.
    # @return [Symbol, String] original paper profile name
    # @see Sevgi::Toplevel#Paper
    def self.Paper(...) = Sevgi.Paper(...)

    # Defines or overwrites a named paper profile.
    # @return [Symbol, String] original paper profile name
    # @see Sevgi::Toplevel#Paper!
    def self.Paper!(...) = Sevgi.Paper!(...)
  end
end
