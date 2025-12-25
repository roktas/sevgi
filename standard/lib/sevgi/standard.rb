# frozen_string_literal: true

require "sevgi/function"

require_relative "standard/internal"
require_relative "standard/errors"
require_relative "standard/version"

require_relative "standard/data"
require_relative "standard/conform"

module Sevgi
  module Standard
    extend self

    def attributes(...)  = Attribute.set(...)

    def attribute?(name) = Attribute.all.include?(name.to_sym)

    def conform(...)     = Conform.(...)

    def elements(...)    = Element.set(...)

    def element?(name)   = Element.all.include?(name.to_sym)

    def model?(...)      = Specification.model?(...)

    def [](name)         = Specification[name.to_sym]
  end
end
