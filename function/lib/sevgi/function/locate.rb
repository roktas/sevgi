# frozen_string_literal: true

module Sevgi
  module Function
    class Locate
      def self.call(*, **, &block) = new(*, **).call(&block)

      Location = Data.define(:file, :slug, :dir)

      private_constant :Location

      attr_reader :paths, :start, :exclude

      def initialize(paths, start = ::Dir.pwd, exclude: nil)
        @paths   = Array(paths)
        @start   = start
        @exclude = [ *exclude ].map { ::File.expand_path(it) } unless exclude.nil?
      end

      def call(&block)
        origin = ::Dir.pwd
        ::Dir.chdir(start)

        here = ::Dir.pwd
        until (found = match(&block))
          ::Dir.chdir("..")
          ::Dir.pwd == here ? return : here = ::Dir.pwd
        end

        Location[::File.expand_path(found, here), found, here]
      ensure
        ::Dir.chdir(origin)
      end

      private

        def match(&block)
          finder = block ||
            if exclude.nil?
              proc { |path| ::File.exist?(path) }
            else
              proc { |path| !exclude.include?(::File.expand_path(path)) && ::File.exist?(path) }
            end

          paths.find { finder.call(it) }
        end
    end

    def self.locate(filename, start, exclude: nil, extension: EXTENSION)
      Locate.(F.qualify(filename, extension), start, exclude:).tap do
        raise(Error, "Cannot load a file matching: #{filename}") unless it
      end
    end
  end
end
