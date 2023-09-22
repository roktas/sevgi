# frozen_string_literal: true

module Sevgi
  class Error < StandardError
    class << self
      def call(...) = raise(self, ...)
    end
  end

  ArgumentError = Class.new(Error)
end
