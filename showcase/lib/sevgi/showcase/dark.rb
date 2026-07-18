# frozen_string_literal: true

module Sevgi
  module Showcase
    # Applies dark-theme color mappings to showcase source files.
    # @api private
    module Dark
      extend self

      # Applies a color mapping to source text.
      # @param source [String] source text
      # @param mapping [Hash{String => String}] source color to dark color mapping
      # @return [String] transformed source text
      # @raise [Sevgi::ArgumentError] when a mapping key is not found
      def apply(source, mapping)
        applied = Hash.new(0)
        content = replace_quoted(source, mapping, applied)
        content = replace_percent_words(content, mapping, applied)
        missing = mapping.keys.reject { applied[it].positive? }

        ArgumentError.("Unapplied dark mapping(s): #{missing.join(", ")}") unless missing.empty?

        content
      end

      # Applies a color mapping to a source file and preserves its mode.
      # @param source [String] source file path
      # @param target [String] target file path
      # @param mapping [Hash{String => String}] source color to dark color mapping
      # @return [String] target file path
      # @raise [Sevgi::ArgumentError] when a mapping key is not found
      def apply_file(source, target, mapping)
        target.tap do
          File.write(target, apply(File.read(source), mapping))
          File.chmod(File.stat(source).mode & 0o777, target)
        end
      end

      private

      def replace_percent_words(source, mapping, applied)
        source.gsub(/%[wW]\[[^\]]*\]/m) do |literal|
          mapping.reduce(literal) do |text, (key, value)|
            text.gsub(/(^|[\s\[])(#{Regexp.escape(key)})(?=$|[\s\]])/) do
              applied[key] += 1
              "#{Regexp.last_match(1)}#{value}"
            end
          end
        end
      end

      def replace_quoted(source, mapping, applied)
        source.gsub(/(?<quote>["'])(?<value>.*?)\k<quote>/) do |literal|
          key = Regexp.last_match[:value]
          value = mapping[key]
          next literal unless value

          applied[key] += 1
          "#{Regexp.last_match[:quote]}#{value}#{Regexp.last_match[:quote]}"
        end
      end
    end

    private_constant :Dark
  end
end
