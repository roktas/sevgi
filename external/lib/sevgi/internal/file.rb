# frozen_string_literal: true

module Sevgi
  module Function
    module File
      def existing(file, extensions)
        return file if ::File.exist?(file)
        return nil unless ::File.extname(file).empty?
        return nil if extensions.empty?

        extensions.map { |ext| "#{file}.#{ext}" }.detect { |file| ::File.exist?(file) }
      end

      def existing!(file, extensions)
        existing(file, extensions).tap do |found|
          raise(ArgumentError, "No matching file(s) found: #{file}") unless found
        end
      end

      def existings(*files, extensions: [])
        {}.tap do |existings|
          files.compact.each { |file| existings[file] = existing(file, extensions) }
        end
      end

      def existings!(...)
        existings = F.existings(...)
        missings = existings.select { |_, match| match.nil? }.keys

        raise(ArgumentError, "No matching file(s) found: #{missings.join(", ")}") unless missings.empty?

        existings
      end

      def qualify(file, default_extension)
        return file unless ::File.extname(file).empty?

        "#{file}.#{default_extension}"
      end
    end

    extend File
  end
end
