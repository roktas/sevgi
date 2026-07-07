# frozen_string_literal: true

module Sevgi
  unless defined?(Error)
    class Error < StandardError
      def self.call(*, **, &) = raise(self, *, **, &)
    end
  end

  module Geometry
    # Base error for geometry input and operation failures.
    Error = Class.new(Error)
  end
end
