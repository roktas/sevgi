# frozen_string_literal: true

module Sevgi
  unless defined?(Error)
    class Error < StandardError
      def self.call(*, **, &) = raise(self, *, **, &)
    end
  end

  module Geometry
    Error = Class.new(Error)
  end
end
