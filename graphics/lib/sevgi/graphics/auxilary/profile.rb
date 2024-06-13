# frozen_string_literal: true

module Sevgi
  module Graphics
    class Profile
      @available = {}

      class << self
        attr_reader :available

        def call(document, canvas = nil, **, &block)
          (klass = self[document]).root(**klass.attributes, **(canvas ? Canvas.(canvas).attributes : {}), **, &block)
        end

        def register(name, klass) = (available[name] = klass)

        def [](name)              = available[name]
      end

      attr_reader :name, :attributes, :preambles

      def initialize(name, attributes: nil, preambles: nil)
        @name       = name
        @attributes = attributes || {}
        @preambles  = preambles
      end

      module DSL
        attr_reader :profile

        def document(name, attributes: {}, preambles: nil)
          @profile = Profile.new(name, attributes:, preambles:).tap do
            Profile.register(name, self)
          end
        end

        def mixture(*modules)
          modules.each do |mod|
            if defined?(mod::InstanceMethods) || defined?(mod::ClassMethods)
              include(mod::InstanceMethods) if defined?(mod::InstanceMethods)
              extend(mod::ClassMethods)     if defined?(mod::ClassMethods)
            else
              include(mod)
            end
          end
        end
      end
    end
  end
end
