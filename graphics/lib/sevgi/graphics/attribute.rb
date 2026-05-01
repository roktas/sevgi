# frozen_string_literal: true

# Some parts are adapted from https://github.com/DannyBen/victor (lib/victor/attributes.rb)

module Sevgi
  module Graphics
    ATTRIBUTE_INTERNAL_PREFIX = "-"
    ATTRIBUTE_UPDATE_SUFFIX   = "+"

    module Attribute
      module Ident
        def internal?(given)
          (@internal ||= {})[given] ||= given.start_with?(ATTRIBUTE_INTERNAL_PREFIX)
        end

        def id(given)
          (@id ||= {})[given] ||= (updateable?(given) ? given.to_s.delete_suffix(ATTRIBUTE_UPDATE_SUFFIX) : given).to_sym
        end

        def updateable?(given)
          (@updateable ||= {})[given] ||= given.end_with?(ATTRIBUTE_UPDATE_SUFFIX)
        end
      end

      extend Ident

      class Store
        def initialize(attributes = {})
          @store = {}

          import(attributes)
        end

        def import(attributes)
          hash = attributes.compact.to_a.map do |key, value|
            [ key.to_sym, value.is_a?(::Hash) ? value.transform_keys!(&:to_sym) : value ]
          end.to_h

          @store.merge!(hash)
        end

        def [](key)
          @store[Attribute.id(key)]
        end

        def []=(key, value)
          return if value.nil?

          @store[id = Attribute.id(key)] = @store.key?(id) && Attribute.updateable?(key) ? update(id, value) : value
        end

        def delete(key)
          @store.delete(Attribute.id(key))
        end

        def export
          hash = @store.reject { |id, _| Attribute.internal?(id) }
          return hash unless hash.key?(:id)

          # A small aesthetic touch: always keep the id attribute first
          { id: hash.delete(:id), **hash }
        end

        def has?(key)
          @store.key?(Attribute.id(key))
        end

        def initialize_copy(original)
          @store = {}
          original.store.each { |key, value| @store[key] = value.dup }

          super
        end

        def list
          export.keys
        end

        def to_h
          @store
        end

        def to_xml_lines
          export.map { |id, value| to_xml(id, value) }
        end

        protected

          attr_reader :store

        private

          UPDATER = {
            ::String => proc { |old_value, new_value| [ old_value, new_value ].reject(&:empty?).join(" ") },
            ::Symbol => proc { |old_value, new_value| [ old_value, new_value ].reject(&:empty?).join(" ").to_sym },
            ::Array  => proc { |old_value, new_value| [ old_value, new_value ] },
            ::Hash   => proc { |old_value, new_value| merge(old_value, new_value.transform_keys(&:to_sym)) }
          }.freeze

          def update(id, new_value)
            (old_value = @store[id]).nil? ? new_value : UPDATER[new_value.class].call(*sanitized(old_value, new_value))
          end

          def sanitized(old_value, new_value)
            ArgumentError.("Incompatible values: #{new_value} vs #{old_value}") unless new_value.is_a?(old_value.class)
            ArgumentError.("Unsupported value for update: #{new_value}")        unless UPDATER.key?(new_value.class)

            [ old_value, new_value ]
          end

          private_constant :UPDATER

          def to_xml(id, value)
            case value
            when ::Hash  then %(#{id}="#{value.map { "#{_1}:#{_2}" }.join("; ")}")
            when ::Array then %(#{id}="#{value.join(" ")}")
            else              %(#{id}=#{value.to_s.encode(xml: :attr)})
            end
          end
      end
    end

    Attributes = Attribute::Store
  end
end
