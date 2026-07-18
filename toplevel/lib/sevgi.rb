# frozen_string_literal: true

require "sevgi/derender"
require "sevgi/function"
require "sevgi/geometry"
require "sevgi/graphics"
require "sevgi/standard"
require "sevgi/sundries"

require "sevgi/version"

# Minimal top-level SVG interface installed by `require "sevgi"`.
# @return [Module] the graphics module used as the SVG DSL namespace
SVG = Sevgi::Graphics

# @overload SVG(document = :default, canvas = Undefined, **attributes, &block)
#   Builds an SVG document through the default top-level DSL entrypoint.
#   @param document [Symbol, String, Class] document profile name or document class
#   @param canvas [Sevgi::Graphics::Canvas, Sevgi::Graphics::Paper, Symbol, String, Sevgi::Undefined, nil] optional
#     canvas or paper profile
#   @param attributes [Hash] root SVG attributes
#   @yield the document block evaluated in the SVG document context
#   @yieldreturn [void]
#   @return [Sevgi::Graphics::Document::Proto] a rendered SVG document object
#   @raise [Sevgi::ArgumentError] when the document, paper, or canvas arguments are invalid
# @example Build through the global library entrypoint
#   SVG(:minimal) { circle r: 4 }.Render
# @see Sevgi.SVG
# @see Sevgi::Toplevel#SVG
def SVG(...) = Sevgi.SVG(...)

# Full top-level API for Sevgi library and script consumers.
#
# `require "sevgi"` installs one global method, `SVG(...)`, and the `SVG` constant naming {Graphics}. The same document
# entrypoint and the rest of the library API are available explicitly on `Sevgi`, such as `Sevgi.SVG`, `Sevgi.Paper`,
# `Sevgi.Grid`, and `Sevgi.Derender`.
#
# Including this module in a class or module installs the DSL methods plus convenience constants `F`, `Geometry`,
# `Origin`, and `Export`; script execution provides the same promoted scope. Extending a module does the same. Extending
# an ordinary object installs methods only and does not write promoted constants to `Object`. Focused component requires
# expose their namespaced component APIs instead of this full top-level surface.
#
# `Load` is meaningful only during {Sevgi.execute}, {Sevgi.execute_file}, or command-line script execution. It resolves
# nested `.sevgi` files through the active executor scope; it is not a general-purpose replacement for Ruby `require`.
#
# @example Include the DSL in an object
#   class Drawing
#     include Sevgi
#   end
module Sevgi
  # See sevgi/toplevel/*.rb files for details
  require_relative "sevgi/toplevel"

  # @!method self.SVG(...)
  #   Builds an SVG document through the explicit namespaced top-level API.
  #   @return [Sevgi::Graphics::Document::Proto] SVG document object
  #   @see Sevgi::Toplevel#SVG
  # @!method self.Mixin(...)
  #   Extends a document profile with a named or anonymous graphics mixture.
  #   @return [Module, nil] anonymous mixture when supplied, otherwise nil
  #   @see Sevgi::Toplevel#Mixin
  # @!method self.Paper(...)
  #   Defines or validates a named paper profile.
  #   @return [Symbol, String] original paper profile name
  #   @see Sevgi::Toplevel#Paper
  # @!method self.Paper!(...)
  #   Defines or overwrites a named paper profile.
  #   @return [Symbol, String] original paper profile name
  #   @see Sevgi::Toplevel#Paper!
  # @!method self.Grid(...)
  #   Fits a drawable grid to a graphics canvas.
  #   @return [Sevgi::Sundries::Grid] fitted grid
  #   @see Sevgi::Toplevel#Grid
  # @!method self.Decompile(...)
  #   Converts inline SVG/XML into an immutable Derender node.
  #   @return [Sevgi::Derender::Node] selected node
  #   @see Sevgi::Toplevel#Decompile
  # @!method self.DecompileFile(...)
  #   Converts an SVG/XML file into an immutable Derender node.
  #   @return [Sevgi::Derender::Node] selected node
  #   @see Sevgi::Toplevel#DecompileFile
  # @!method self.Derender(...)
  #   Converts inline SVG/XML into formatted Sevgi DSL source.
  #   @return [String] formatted Sevgi DSL source
  #   @see Sevgi::Toplevel#Derender
  # @!method self.DerenderFile(...)
  #   Converts an SVG/XML file into formatted Sevgi DSL source.
  #   @return [String] formatted Sevgi DSL source
  #   @see Sevgi::Toplevel#DerenderFile
  # @!method self.Evaluate(...)
  #   Includes an inline SVG/XML node under a graphics element.
  #   @return [Sevgi::Graphics::Element, nil] included element, or nil when no output is produced
  #   @see Sevgi::Toplevel#Evaluate
  # @!method self.EvaluateFile(...)
  #   Includes an SVG/XML file node under a graphics element.
  #   @return [Sevgi::Graphics::Element, nil] included element, or nil when no output is produced
  #   @see Sevgi::Toplevel#EvaluateFile
  # @!method self.EvaluateChildren(...)
  #   Includes only an inline SVG/XML node's children under a graphics element.
  #   @return [Array<Sevgi::Graphics::Element>] immutable included-child snapshot
  #   @see Sevgi::Toplevel#EvaluateChildren
  # @!method self.EvaluateChildrenFile(...)
  #   Includes only an SVG/XML file node's children under a graphics element.
  #   @return [Array<Sevgi::Graphics::Element>] immutable included-child snapshot
  #   @see Sevgi::Toplevel#EvaluateChildrenFile
  # @!method self.Load(...)
  #   Loads nested `.sevgi` files through the active executor scope.
  #   @return [Array<String>] requested file names
  #   @see Sevgi::Toplevel#Load

  # Installs the full toplevel DSL into an including class or module.
  # @param base [Module] the class or module receiving the DSL methods
  # @return [void]
  # @api private
  def self.included(base)
    super
    base.include(Toplevel)
  end

  # Installs the full toplevel DSL into an extending object or module.
  # @param base [Object] the receiver extended with the DSL methods
  # @return [void]
  # @note Promoted constants are written only when base is a module or class.
  # @api private
  def self.extended(base)
    super
    base.extend(Toplevel)
  end

  private_class_method :extended, :included
end
