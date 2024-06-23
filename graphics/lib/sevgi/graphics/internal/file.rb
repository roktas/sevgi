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

      def out(content, *paths, update: false, &filter)
        if paths.empty?
          ::Kernel.puts(content)
        else
          file   = ::File.expand_path(::File.join(*paths))
          output = "#{content.chomp}\n"

          ::File.write(file, output) if !update || changed?(file, output, &filter)
        end
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
