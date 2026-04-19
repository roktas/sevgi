# frozen_string_literal: true

module Sevgi
  class Error < StandardError
    def self.call(...) = raise(self, ...)
  end unless defined?(Error)

  module Geometry
    Error = Class.new(Error)
  end
end
