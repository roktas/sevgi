# frozen_string_literal: true

require "json"

module Sevgi
  module Sundries
    module Export
      # Validated inputs shared by ordinary and prepared export.
      # @api private
      class Input
        attr_reader :dimensions, :fallback, :style, :svg

        def initialize(svg, options, &block)
          @fallback = options.fetch(:fallback)
          ArgumentError.("Export fallback must be true or false") unless [true, false].any? { it.equal?(fallback) }
          @dimensions = %i[width height dpi].to_h do |key|
            [key, dimension(options[key], key.to_s, optional: key != :dpi)]
          end
          @style = declaration(options[:style])
          @svg = source(svg, options[:css], &block).dup.freeze
        end

        private

        def declaration(value)
          return if value.nil?
          ArgumentError.("Export Style must be a Hash") unless value.is_a?(::Hash)
          JSON.generate(value, strict: true, max_nesting: 32).freeze
        rescue JSON::JSONError => e
          ArgumentError.("Invalid Style JSON: #{e.message}")
        end

        def source(svg, css)
          ArgumentError.("SVG content must be a String") unless svg.is_a?(String)
          css = stylesheet(css)
          svg = Export.send(:styled, svg, css) if css
          svg = yield(svg) if block_given?
          ArgumentError.("SVG content must be a String") unless svg.is_a?(String)
          svg
        end

        def stylesheet(css)
          return if css.nil?
          ArgumentError.("Export CSS must be a String") unless css.is_a?(String)
          ArgumentError.("Export CSS must be valid text") unless css.valid_encoding?
          css unless css.strip.empty?
        end

        # Numeric coercion and finite positive admission are one boundary check.
        # rubocop:disable-next Metrics/CyclomaticComplexity
        def dimension(value, field, optional: true)
          return if value.nil? && optional
          ExportError.(dimension_error(field)) unless value.is_a?(::Numeric)
          number = begin
            value.to_f
          rescue ::StandardError => e
            ExportError.(dimension_error(field, e.message))
          end
          ExportError.(dimension_error(field)) unless number.is_a?(::Float) && number.finite? && number.positive?
          number
        end

        def dimension_error(field, detail = nil)
          message = [
            (%w[width height].include?(field) ? "Invalid export dimensions" : "Invalid export #{field}"),
            detail
          ]
          message.compact.join(": ")
        end
      end

      private_constant :Input
    end
  end
end
