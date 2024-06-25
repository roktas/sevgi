# frozen_string_literal: true

require "sevgi"

def Exec(file, *args, **kwargs)
  location = Sevgi.locate(file, ::File.dirname(exclude = caller_locations(1..1).first.path), exclude:)

  Sevgi::Sandbox.run(location.file) do |this|
    include Sevgi::External

    this.const_set(:ARGA, args).freeze
    this.const_set(:ARGH, kwargs).freeze
  end
end