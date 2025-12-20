# frozen_string_literal: true

module Sevgi
  module Function
    module Kernel
      def load(file, inspect: nil)
        eval(::File.read(file), file, 1, inspect: inspect || "(loaded from #{file})")
        true
      end

      def eval(string, file = nil, line = nil, inspect: nil, caller_offset: 1)
        unless file && line
          location = caller_locations(caller_offset, 1)&.first or
            raise ArgumentError, "Cannot determine caller location"

          file ||= location.path
          line ||= location.lineno
        end

        mod = Module.new

        if inspect
          mod.define_singleton_method(:inspect) { inspect }
          mod.define_singleton_method(:to_s)    { inspect }
        end

        mod.module_eval(string, file, line)
      end
    end

    extend Kernel
  end
end
