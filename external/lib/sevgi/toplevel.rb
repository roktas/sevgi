# frozen_string_literal: true

module Sevgi
  def exec(file, *args, **kwargs)
    Sevgi::Sandbox.run(F.existing!(file, [ EXTENSION ])) do |mod|
      include Sevgi::External

      mod.const_set(:ARGA, args).freeze
      mod.const_set(:ARGH, kwargs).freeze
    end
  end

  extend self
end
