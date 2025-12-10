# frozen_string_literal: true

require_relative "internal"

module Sevgi
  # Externals management DSL for consumers

  module External
    @constants = {}

    class << self
      private

        def Promote(constant, symbol = Undefined)
          @constants[Undefined.default(symbol, constant.to_s.split("::").last.to_sym)] = constant
        end
    end

    def Extern(*modules, &block)
      ::Sevgi::External.tap do |external|
        external.module_exec(&block)
        modules.each { external.include(it) }
        ::Sevgi.extend(external)
      end
    end

    def Extern!(receiver, ...)
      receiver.send(:include, Extern(...))
    end

    def Load(*files)
      start = ::File.dirname(caller_locations(1..1).first.path)

      files.each do |file|
        location = Sevgi.locate(file, start, exclude: start)

        Sandbox.load(location.file)
      end
    end

    def self.included(base)
      return if base.instance_variable_defined?("@_external_included_")

      super

      @constants.each { |args| base.const_set(*args) }

      base.instance_variable_set("@_external_included_", true)
    end
  end

  extend External

  require_relative "external/derender"
  require_relative "external/function"
  require_relative "external/geometry"
  require_relative "external/graphics"
  require_relative "external/sundries"
end

include Sevgi::External
