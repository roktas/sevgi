# frozen_string_literal: true

require_relative "data/color"

module Sevgi
  module Standard
    # Defensive copy helper for public standard-data snapshots.
    # @api private
    module Snapshot
      # Returns a recursively independent copy of a value.
      # @param value [Object] value to copy
      # @return [Object] copied value
      def self.copy(value)
        case value
        when ::Hash
          hash(value)
        when ::Array
          value.map { copy(it) }
        when ::Set
          Set[*value.map { copy(it) }]
        else
          duplicate(value)
        end
      end

      def self.hash(value) = value.to_h { |key, item| [key, copy(item)] }

      def self.duplicate(value)
        value.dup
      rescue ::TypeError
        value
      end

      private_class_method :duplicate, :hash
    end

    private_constant :Snapshot

    # Shared set operations for SVG standard data lists.
    # @api private
    module Common
      # Returns every known name in this data list.
      # @return [Set<Symbol>] mutation-isolated set snapshot
      def all = Snapshot.copy(@all ||= Set[*data.values.flatten.uniq.sort])

      # Returns accepted group names for this data list.
      # @return [Set<Symbol>] frozen group-name snapshot
      def groups = @groups ||= Set[*data.keys.sort].freeze

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
      # @param groups [Array<String, Symbol>] group names
      # @return [Set<Symbol>] mutation-isolated selected-name snapshot
      def set(*groups)
        return all if groups.empty?

        Set[*data.values_at(*groups!(groups)).flatten.uniq.sort]
      end

      # Removes names that belong to any requested group.
      # @param names [Array<Symbol>] names to filter
      # @param groups [Array<Symbol>] group names
      # @return [Array<Symbol>] filtered names
      def unpick(names, *groups) = names.reject { |name| groups.any? { is?(name, it) } }

      def groups!(groups)
        groups = groups.map { Name.normalize!(it, context: "group") }
        unknown = groups.reject { data.key?(it) }
        ArgumentError.("Unknown SVG group(s): #{unknown.map(&:inspect).join(", ")}") unless unknown.empty?

        groups
      end

      private :groups!

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

    # SVG attribute registry implementation.
    # @api private
    module Attribute
      extend Common
      extend self

      require_relative "data/attribute"
    end

    private_constant :Attribute

    # SVG element registry implementation.
    # @api private
    module Element
      extend Common
      extend self

      require_relative "data/element"
    end

    private_constant :Element

    # SVG specification registry implementation.
    # @api private
    module Specification
      extend List
      extend self

      require_relative "data/specification"

      # Returns expanded standard specification data for one element.
      # @param name [Symbol] SVG element name
      # @return [Hash, nil] mutation-isolated expanded specification snapshot
      def [](name) = Snapshot.copy(expand(name))

      # Reports whether a name is a data group name.
      # @param name [Symbol] element or group name
      # @return [Boolean]
      def group?(name) = /[[:upper:]]/.match?(name[0])

      # Checks whether an element uses one of the requested content models.
      # @param name [String, Symbol] SVG element name
      # @param models [Array<String, Symbol>] model names to match
      # @return [Boolean]
      # @raise [Sevgi::ArgumentError] when any name is not a valid public name
      def model?(name, *models)
        name = Name.normalize!(name, context: "element")
        models = models.map { Name.normalize!(it, context: "model") }

        models.any? { (self[name] || {})[:model] == it }
      end

      private

      @spec = {}

      def expand(name)
        return unless data.key?(name)

        @spec[name] ||= data
          .fetch(name)
          .transform_values { |value| value.is_a?(::Array) ? value.dup : value }
          .tap do |spec|
            expand_names(spec[:elements], Element.send(:data))
            expand_names(spec[:attributes], Attribute.send(:data))
          end
      end

      def expand_names(names, list)
        return unless names

        names.replace(names.flat_map { |name| group?(name) ? list[name] : name }.uniq)
      end

      # For testing purposes

      def charge = data.each_key { expand(it) }

      def flush = (@spec = {})
    end

    private_constant :Specification
  end
end
