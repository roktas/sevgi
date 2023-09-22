# frozen_string_literal: true

module Sevgi
  class Locate
    Location = Data.define(:file, :slug, :dir)

    private_constant :Location

    attr_reader :slugs, :start

    def initialize(slugs, start = Dir.pwd)
      @slugs  = slugs
      @start  = start
    end

    def call(&block)
      origin = Dir.pwd
      Dir.chdir(start)

      here = Dir.pwd
      until (found = match(&block))
        Dir.chdir("..")
        return if Dir.pwd == here

        here = Dir.pwd
      end

      Location[::File.expand_path(found, here), found, here]
    ensure
      Dir.chdir(origin)
    end

    private

    def match(&block)
      finder = block || proc { |path| ::File.exist?(path) }

      slugs.find { finder.call(_1) }
    end

    class << self
      def call(*, &block) = new(*).call(&block)
    end
  end

  private_constant :Locate
end
