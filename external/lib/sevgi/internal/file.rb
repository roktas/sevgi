# frozen_string_literal: true

require "digest"
require "fileutils"
require "pathname"

module Sevgi
  module Function
    module File
      def changed?(file, content)
        ::File.exist?(file) ? Digest::SHA1.digest(::File.read(file)) != Digest::SHA1.digest(content) : true
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

      def out(content, *paths, update: false)
        if paths.empty?
          ::Kernel.puts(content)
        else
          file   = ::File.expand_path(::File.join(*paths))
          output = "#{content.chomp}\n"

          ::File.write(file, output) if !update || changed?(file, output)
        end
      end

      def qualify(file, default_extension)
        return file unless ::File.extname(file).empty?

        "#{file}.#{default_extension}"
      end

      def touch(*paths, ext: nil)
        path = ::File.join(*paths)
        path = Pathname.new(path).sub_ext(ext) if ext

        ::FileUtils.mkdir_p(::File.dirname(path))
        ::FileUtils.touch(path)

        path
      end
    end

    extend File
  end
end
