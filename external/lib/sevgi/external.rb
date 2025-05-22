# frozen_string_literal: true

require_relative "internal"

# The Sevgi module serves as the main namespace for the Sevgi library.
# This file (`external/lib/sevgi/external.rb`) specifically defines the
# `Sevgi::External` submodule and related DSL functionalities.
# For primary documentation of the Sevgi module, see the main `sevgi.rb` file.
module Sevgi
  # The External module provides a DSL for consumers to extend Sevgi's functionality,
  # primarily by incorporating features from other Sevgi components like Graphics and Geometry,
  # and by providing utility methods for loading files or defining custom behaviors.
  #
  # The module is designed to be extended into the main Sevgi module or included into specific classes.
  # It uses a mechanism (`Promote`) to make constants from other modules available.
  module External
    # @!visibility private
    # Internal store for constants to be promoted.
    @constants = {}

    class << self
      private

        # @!visibility private
        # Registers a constant to be promoted (i.e., made available in the including context).
        #
        # @param constant [Object] The constant to promote (e.g., a Module or Class).
        # @param symbol [Symbol, Undefined] The symbol under which to make the constant available.
        #   If Undefined, the symbol is derived from the constant's name.
        # @return [void]
        def Promote(constant, symbol = Undefined)
          @constants[Undefined.default(symbol, constant.to_s.split("::").last.to_sym)] = constant
        end
    end

    # Extends the `Sevgi::External` module itself with the given modules and block,
    # and then extends the main `Sevgi` module with this augmented `Sevgi::External` module.
    # This makes the defined methods and included modules available at the top level of `Sevgi`.
    #
    # @param modules [Array<Module>] Modules to include into `Sevgi::External`.
    # @param block [Proc] A block to be executed in the context of `Sevgi::External`.
    # @return [Sevgi::External] The `Sevgi::External` module.
    def Extern(*modules, &block)
      ::Sevgi::External.tap do |external|
        external.module_exec(&block) if block
        modules.each { |mod| external.include(mod) } # Changed `it` to `mod` for clarity
        ::Sevgi.extend(external)
      end
    end

    # Includes the `Sevgi::External` module (as augmented by `Extern(...)`) into a given receiver class or module.
    #
    # @param receiver [Module] The class or module into which `Sevgi::External` will be included.
    # @param ... [Object] Arguments to be passed to `Extern` (modules and/or a block).
    # @return [void]
    def Extern!(receiver, ...)
      receiver.send(:include, Extern(...))
    end

    # @!visibility private
    # Callback invoked when `Sevgi::External` is included into another module or class.
    # It sets the promoted constants on the base module/class.
    def self.included(base)
      return if base.instance_variable_defined?("@_external_included_")

      super

      @constants.each { |args| base.const_set(*args) }

      base.instance_variable_set("@_external_included_", true)
    end
  end

  extend External # Make Extern and Extern! available on Sevgi module itself initially.

  # --- Externals for Graphics ---

  require "sevgi/graphics"

  # @!parse include Sevgi::Graphics::Callable
  # Makes methods from `Sevgi::Graphics::Callable` available.
  Callable = Graphics::Callable # This makes Callable available directly.

  # Reopening External to add Graphics-specific DSL methods.
  module External
    # Defines a new paper size for use in graphics documents.
    #
    # @param width [Numeric] The width of the paper.
    # @param height [Numeric] The height of the paper.
    # @param name [Symbol] The name to assign to this paper definition (default: `:custom`).
    # @param unit [String] The unit for width and height (default: "mm").
    # @return [Symbol] The name of the defined paper.
    # @see Sevgi::Graphics::Paper.define!
    def Paper(width, height, name = :custom, unit: "mm")
      name.tap { Graphics::Paper.define!(name, width:, height:, unit:) }
    end

    # Adds a mixin module or a block-defined module to a graphics document class.
    # This allows extending the functionality of graphics documents.
    #
    # @param mod [Module] The module to mixin.
    # @param document [Class<Sevgi::Graphics::Document::Base>] The document class to extend (default: `Graphics::Document::Base`).
    # @param block [Proc, nil] An optional block that defines an anonymous module to mixin.
    # @return [void]
    # @see Sevgi::Graphics::Document::Base.mixture
    def Mixin(mod, document = Graphics::Document::Base, &block)
      document.mixture(mod)
      document.mixture(::Module.new(&block)) if block
    end

    # A convenience method to delegate to `Sevgi::Graphics.SVG`.
    # Typically used for creating or manipulating SVG content.
    #
    # @param ... [Object] Arguments passed to `Graphics.SVG`.
    # @return [Object] The result of `Graphics.SVG(...)`.
    # @see Sevgi::Graphics.SVG
    def SVG(...)
      Graphics.SVG(...)
    end
  end

  # --- Externals for Geometry ---

  require "sevgi/geometry"

  # Reopening External to add Geometry-specific constants.
  module External
    # Promotes the `Sevgi::Geometry` module itself, making its contents (classes like Point, Line, etc.)
    # available directly within the scope where `Sevgi::External` is included/extended.
    # @!parse include Sevgi::Geometry
    Promote Geometry
    # Promotes `Sevgi::Geometry::Origin` as `Origin`.
    # Provides a shortcut to the geometric origin point (0,0).
    # @!parse O = Sevgi::Geometry::Origin
    Promote Geometry::Origin, :Origin
  end

  # --- Other externals ---

  # Reopening External to add general utility DSL methods.
  module External
    # Loads Ruby files within a sandboxed environment.
    # The files are located relative to the directory of the calling script.
    #
    # @param files [Array<String>] A list of file paths or patterns to load.
    # @return [void]
    # @see Sevgi.locate
    # @see Sevgi::Sandbox.load
    def Load(*files)
      start = ::File.dirname(caller_locations(1..1).first.path)

      files.each do |file|
        location = Sevgi.locate(file, start, exclude: start)
        raise "File not found: #{file}" unless location # Added error handling

        Sandbox.load(location.file)
      end
    end

    # A module that extends `Sevgi::Function::Math` to provide mathematical functions.
    # This module is then promoted as `F`.
    module Function
      extend Sevgi::Function::Math
    end

    # Promotes the `Function` module (containing math functions) as `F`.
    # This makes math functions available via `F.cos`, `F.sin`, etc.
    # @!parse F = Sevgi::External::Function
    Promote Function, :F
  end
end
