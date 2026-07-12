# frozen_string_literal: true

module Sevgi
  module Graphics
    # Output path normalization shared by Graphics writers and exporters.
    # @api private
    module Path
      # Converts a non-blank path to an expanded String.
      # @param value [String, #to_path] raw path value
      # @param context [String] public operation named in errors
      # @return [String] expanded path
      # @raise [Sevgi::ArgumentError] when value is blank, has an invalid type, or path conversion fails
      def self.call(value, context:)
        path = value.respond_to?(:to_path) ? value.to_path : value
        ArgumentError.("#{context} must be a String or path-like object") unless path.is_a?(::String)
        ArgumentError.("#{context} must be provided") if path.strip.empty?

        ::File.expand_path(path)
      rescue ::Sevgi::ArgumentError
        raise
      rescue ::StandardError => e
        ArgumentError.("#{context} must be a String or path-like object: #{e.message}")
      end

      # Resolves an optional path with the writer/exporter directory convention.
      # @param value [String, #to_path, nil] explicit path or directory
      # @param default [String, #to_path] default output path
      # @param context [String] public operation named in errors
      # @return [String] expanded output file path
      # @raise [Sevgi::ArgumentError] when a selected path/default is blank, invalid, or cannot be converted
      def self.resolve(value, default:, context:)
        return call(default, context: "#{context} default") if value.nil?

        path = call(value, context: "#{context} path")
        return path unless ::File.directory?(path)

        default = call(default, context: "#{context} default")
        ::File.join(path, ::File.basename(default))
      end
    end

    private_constant :Path
  end
end
