# frozen_string_literal: true

require_relative "data/color"

module Sevgi
  module Standard
    module Common
      def all                    = @all ||= Set[*data.values.flatten.uniq.sort]

      def is?(name, group)       = self[group].include?(name)

      def pick(names, *groups)   = names.select { |name| groups.any? { is?(name, it) } }

      def set(*groups)           = groups.empty? ? all : Set[*data.values_at(*groups).flatten.compact.uniq.sort]

      def unpick(names, *groups) = names.reject { |name| groups.any? { is?(name, it) } }

      def concerns(names)        = names ? names.reject { ignore?(it) } : names

      def self.extended(base)    = base.extend(List)
    end

    private_constant :Common

    module Attribute
      extend Common
      extend self

      require_relative "data/attribute"
    end

    private_constant :Attribute

    module Element
      extend Common
      extend self

      require_relative "data/element"
    end

    private_constant :Element

    module Specification
      extend List
      extend self

      require_relative "data/specification"

      def [](name)              = expand(name)

      def group?(name)          = /[[:upper:]]/.match?(name[0])

      def model?(name, *models) = models.any? { (self[name] || {})[:model] == name }

      private

        @spec = {}

        def expand(name)
          @spec[name] ||= if data[name]
            data[name].dup.tap do |spec|
              expand_names(spec[:elements],   Element.data)
              expand_names(spec[:attributes], Attribute.data)
            end
          end
        end

        def expand_names(names, list)
          return unless names

          names.replace(names.map { |name| group?(name) ? list[name] : name }.flatten)
        end

        # For testing purposes

        def charge = data.keys { expand(it) }

        def flush  = (@spec = {})
    end

    private_constant :Specification
  end
end
