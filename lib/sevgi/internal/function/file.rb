# frozen_string_literal: true

require "digest"

module Sevgi
  module Function
    module File
      def changed?(file, content)
        ::File.exist?(file) ? Digest::SHA1.digest(::File.read(file)) != Digest::SHA1.digest(content) : true
      end

      def out(content, *paths, smart: false)
        if paths.empty?
          ::Kernel.puts(content)
        else
          file   = ::File.expand_path(::File.join(*paths))
          output = "#{content.chomp}\n"

          ::File.write(file, output) if !smart || changed?(file, output)
        end
      end

      def variations(name, dirs, exts)
        dirs.product(exts).map { |dir, ext| ::File.join(dir, "#{name}.#{ext}") }
      end
    end

    extend File
  end
end
