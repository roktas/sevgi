# frozen_string_literal: true

module Sevgi
  class Executor
    Source = Data.define(:string, :file, :line) do
      def self.call(...)                            = new(...)

      def self.load(file)                           = new(string: ::File.read(file), file: file, line: 1)

      def initialize(string:, file: nil, line: nil) = super(string:, file: file || "sevgi", line: line || 1)

      def key                                       = file
    end
  end
end
