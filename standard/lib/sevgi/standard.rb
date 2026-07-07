# frozen_string_literal: true

require "sevgi/function"

require_relative "standard/internal"
require_relative "standard/errors"

require_relative "standard/data"
require_relative "standard/conform"

require_relative "standard/version"

module Sevgi
  module Standard
    extend self

    def attributes(...) = Attribute.set(...)

    def attribute?(name) = name.respond_to?(:to_sym) && Attribute.all.include?(name.to_sym)

    def conform(...) = Conform.(...)

    def elements(...) = Element.set(...)

    def element?(name) = name.respond_to?(:to_sym) && Element.all.include?(name.to_sym)

    def model?(...) = Specification.model?(...)

    def specification(name) = name.respond_to?(:to_sym) ? Specification[name.to_sym] : nil

    alias [] specification
  end
end
