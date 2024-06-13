# frozen_string_literal: true

module Sevgi
  class Error < StandardError
    class << self
      def call(...) = raise(self, ...)
    end
  end unless defined?(Error)

  module Geometry
    Error = Class.new(Error)
  end
end
