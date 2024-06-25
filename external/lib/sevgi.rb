# frozen_string_literal: true

require "sevgi/geometry"
require "sevgi/standard"
require "sevgi/graphics"
require "sevgi/version"

require "sevgi/external"

module Sevgi
  def self.exec(file, *args, **kwargs)
    Sevgi::Sandbox.run(F.existing!(file, [ EXTENSION ])) do |mod|
      include Sevgi::External

      mod.const_set(:ARGA, args).freeze
      mod.const_set(:ARGH, kwargs).freeze
    end
  end
end
