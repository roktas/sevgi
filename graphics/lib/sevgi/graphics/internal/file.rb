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

      def out(content, *paths, update: false)
        if paths.empty?
          ::Kernel.puts(content)
        else
          file   = ::File.expand_path(::File.join(*paths))
          output = "#{content.chomp}\n"

          ::File.write(file, output) if !update || changed?(file, output)
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
