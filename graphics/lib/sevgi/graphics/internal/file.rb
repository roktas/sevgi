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
