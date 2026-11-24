# frozen_string_literal: true

require "fileutils"
require "tmpdir"

module Sevgi
  module Sundries
    module Export
      # Atomic temporary directory staging helpers for file-producing exports.
      # @api private
      module Staging
        class << self
          # Stages replacement of a target file inside an existing ancestor directory.
          # @param output [String] destination file path
          # @param prefix [String] temporary directory prefix
          # @param filename [String] staged file name
          # @yield [staged] receives the temporary staged file path
          # @yieldparam staged [String] staged file path
          # @yieldreturn [Object] returning false cancels installation
          # @return [String, nil] destination path when installed, or nil when cancelled
          def replace(output, prefix: ".sevgi-export-", filename: "output#{::File.extname(output)}")
            workspace(output, prefix:) do |directory|
              staged = ::File.join(directory, filename)
              return nil if yield(staged) == false

              ::FileUtils.mkdir_p(::File.dirname(output))
              ::File.rename(staged, output)
            end

            output
          end

          # Creates a temporary directory in the nearest existing ancestor of a target path.
          # @param near [String] reference file path
          # @param prefix [String] temporary directory prefix
          # @yield [directory] receives the temporary directory path
          # @yieldparam directory [String] temporary directory path
          # @return [Object] block return value
          def workspace(near, prefix: ".sevgi-export-", &) = ::Dir.mktmpdir(prefix, parent_directory(near), &)

          private

          def parent_directory(path)
            parent = ::File.dirname(path)
            parent = ::File.dirname(parent) until ::File.directory?(parent)
            parent
          end
        end
      end

      private_constant :Staging
    end
  end
end
