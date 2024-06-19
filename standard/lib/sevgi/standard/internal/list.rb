# frozen_string_literal: true

module Sevgi
  module List
    def [](name)         = data[name]

    def import(**kwargs) = data.merge!(kwargs.reject { |key, _| data.key?(key) })

    def valid?(name)     = data.key?(name)

    def self.extended(base)
      super

      base.class_exec do
        @data = {}

        class << self
          attr_reader :data
        end
      end
    end
  end

  private_constant :List
end
