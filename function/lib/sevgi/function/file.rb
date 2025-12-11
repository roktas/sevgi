# frozen_string_literal: true

require "digest"
require "fileutils"
require "pathname"

module Sevgi
  module Function
    module File
      def changed?(file, content, &filter)
        return true unless ::File.exist?(file)

        old_content = ::File.read(file)
        old_content, content = [ old_content, content ].map(&filter) if filter

        Digest::SHA1.digest(old_content) != Digest::SHA1.digest(content)
      end

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

      def out(content, *paths, &filter)
        if paths.empty?
          ::Kernel.puts(content)
        else
          file   = ::File.expand_path(::File.join(*paths))
          output = "#{content.chomp}\n"

          return unless changed?(file, output, &filter)

          file.tap { ::File.write(file, output) }
        end
      end

      def qualify(file, default_extension)
        return file unless ::File.extname(file).empty?

        "#{file}.#{default_extension}"
      end

      def subext(ext, *paths)
        path = ::File.join(*paths)
        return path unless ext

        Pathname.new(path).sub_ext(ext).to_s
      end

      def touch(*paths)
        ::File.join(*paths).tap do |path|
          ::FileUtils.mkdir_p(::File.dirname(path))
          ::FileUtils.touch(path)
        end
      end
    end

    extend File
  end
end
