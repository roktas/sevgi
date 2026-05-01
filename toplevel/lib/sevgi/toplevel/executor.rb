# frozen_string_literal: true

require "sevgi/executor"

module Sevgi
  BootBlock = proc { send(is_a?(::Module) ? :extend : :include, ::Sevgi) }

  private_constant :BootBlock

  def self.execute(*args, **kwargs)      = Executor.execute(*args, **kwargs, &BootBlock)

  def self.execute_file(*args, **kwargs) = Executor.execute_file(*args, **kwargs, &BootBlock)

  module Toplevel
    def Load(*files)
      start = ::File.dirname(caller_locations(1..1).first.path)

      files.each do |file|
        location = F.locate(file, start, exclude: start)

        ::Sevgi::Executor.load(location.file)
      end
    end
  end
end
