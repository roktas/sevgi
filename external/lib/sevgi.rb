# frozen_string_literal: true

require "sevgi/function"

require "sevgi/derender"
require "sevgi/geometry"
require "sevgi/graphics"
require "sevgi/standard"
require "sevgi/sundries"

require "sevgi/version"

require_relative "sevgi/external"

module Sevgi
  def self.exec(file, *args, **kwargs)
    Sevgi::Sandbox.run(F.existing!(file, [ EXTENSION ])) do |mod|
      include Sevgi::External

      mod.const_set(:ARGA, args).freeze
      mod.const_set(:ARGH, kwargs).freeze
    end
  end
end
