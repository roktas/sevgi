# frozen_string_literal: true

module Sevgi
  module Function
    module External
      EXTENSIONS  = ["sevgi", "rb"].freeze
      DIRECTORIES = ["lib", "library"].freeze

      def Lib(name)
        start = ::File.dirname(caller_locations(1..1).first.path)

        paths = F.variations(name, DIRECTORIES, EXTENSIONS)

        raise Error, "No library found matching: #{name}" unless (location = Locate.(paths, start))

        Kernel.load(location.file)
      end

      module Function
        extend Sevgi::Function::Float
        extend Sevgi::Function::Math
      end

      class << self
        def included(base)
          super

          base.const_set(:F, External::Function)
        end
      end
    end
  end

  F = Function
end
