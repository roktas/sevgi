# frozen_string_literal: true

require_relative "data/color"

module Sevgi
  module Standard
    # Shared set operations for SVG standard data lists.
    # @api private
    module Common
      # Returns every known name in this data list.
      # @return [Set<Symbol>]
      def all = @all ||= Set[*data.values.flatten.uniq.sort]

      # Checks whether a name belongs to a group.
      # @param name [Symbol] item name
      # @param group [Symbol] group name
      # @return [Boolean]
      def is?(name, group) = self[group].include?(name)

      # Keeps names that belong to any requested group.
      # @param names [Array<Symbol>] names to filter
      # @param groups [Array<Symbol>] group names
      # @return [Array<Symbol>] filtered names
      def pick(names, *groups) = names.select { |name| groups.any? { is?(name, it) } }

      # Returns all names or names from selected groups.
      # @param groups [Array<Symbol>] group names
      # @return [Set<Symbol>] selected names
      def set(*groups) = groups.empty? ? all : Set[*data.values_at(*groups).flatten.compact.uniq.sort]

      # Removes names that belong to any requested group.
      # @param names [Array<Symbol>] names to filter
      # @param groups [Array<Symbol>] group names
      # @return [Array<Symbol>] filtered names
      def unpick(names, *groups) = names.reject { |name| groups.any? { is?(name, it) } }

      # Removes ignored names from a list.
      # @param names [Array<Symbol>, nil] names to filter
      # @return [Array<Symbol>, nil] names that should be validated
      def concerns(names) = names ? names.reject { ignore?(it) } : names

      # Installs low-level list helpers into data modules.
      # @param base [Module] data module receiving helpers
      # @return [void]
      # @api private
      def self.extended(base) = base.extend(List)
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

      # Returns expanded standard specification data for one element.
      # @param name [Symbol] SVG element name
      # @return [Hash, nil] expanded specification data
      def [](name) = expand(name)

      # Reports whether a name is a data group name.
      # @param name [Symbol] element or group name
      # @return [Boolean]
      def group?(name) = /[[:upper:]]/.match?(name[0])

      # Checks whether an element uses one of the requested content models.
      # @param name [Symbol] SVG element name
      # @param models [Array<Symbol>] model names to match
      # @return [Boolean]
      def model?(name, *models) = models.any? { (self[name] || {})[:model] == it }

      private

      @spec = {}

      def expand(name)
        @spec[name] ||= if data[name]
          data[name].transform_values { |value| value.is_a?(::Array) ? value.dup : value }.tap do |spec|
            expand_names(spec[:elements], Element.data)
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

      def flush = (@spec = {})
    end

    private_constant :Specification
  end
end
