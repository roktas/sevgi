# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "tmpdir"

module Sevgi
  module Sundries
    # Optional CLI boundary for Mainz prepared PDF production.
    # This component does not load the Mainz Ruby extension or native export gems.
    module Mainz
      COMMAND = "mainz"
      private_constant :COMMAND

      # A missing or unsuccessful Mainz producer.
      Error = Class.new(::Sevgi::Error)

      # Reports whether the Mainz executable is installed on PATH.
      # @return [Boolean]
      def available? = F.executable?(COMMAND)

      # Returns the selected executable's content identity for output caches.
      # PATH is resolved on each call. Absence returns nil.
      # @return [Hash{String => Object}, nil] executable SHA-256 and native dependency report
      # @raise [SystemCallError] when the executable cannot be read
      # @raise [Sevgi::Sundries::Mainz::Error] when the version command fails or its report is invalid
      def fingerprint
        path = F.executable(COMMAND)
        return unless path
        process = run(path, "--version")
        report = JSON.parse(process.out)
        Error.("Invalid Mainz version report") unless report.is_a?(Hash) && report["contract"] == 1
        {"sha256" => Digest::SHA256.file(path).hexdigest, "runtime" => report}
      rescue JSON::ParserError => e
        Error.("Invalid Mainz version report: #{e.message}")
      end

      # Produces and atomically replaces one PDF through the native CLI.
      # Input paths and output staging remain private to this call.
      # @param svg [String] SVG source
      # @param output [String, #to_path] destination path
      # @param declaration [Hash] JSON authoring declaration
      # @param options [Hash] ordinary export options
      # @option options [Numeric, nil] :width output width in CSS pixels
      # @option options [Numeric, nil] :height output height in CSS pixels
      # @option options [Numeric] :dpi (96.0) positive CSS pixel density
      # @option options [String, nil] :css export-only CSS
      # @yield [svg] transforms the source once before production
      # @yieldparam svg [String] SVG after optional CSS insertion
      # @yieldreturn [String] source to render
      # @return [String] expanded destination path
      # @raise [Sevgi::ArgumentError] when the source, path, or declaration is invalid
      # @raise [Sevgi::Sundries::Mainz::Error] when Mainz is missing or preparation fails
      # @raise [SystemCallError] when staging or installation fails
      def produce(svg, output, declaration:, **options, &block)
        ArgumentError.("Mainz declaration must be a Hash") unless declaration.is_a?(::Hash)
        unknown = options.keys - %i[css dpi height width]
        ArgumentError.("Unknown Mainz option: #{unknown.first}") unless unknown.empty?
        Export.call(svg, output, format: :pdf, style: declaration, fallback: false, **options, &block)
      end

      extend self

      class << self
        private

        def write(input, output)
          program = F.executable(COMMAND) || Error.("Mainz executable is unavailable")
          parent = ::File.dirname(output)
          parent = ::File.dirname(parent) until ::File.directory?(parent)
          dimensions = input.dimensions.flat_map { |key, value| value.nil? ? [] : ["--#{key}", value.to_s] }
          ::Dir.mktmpdir(".sevgi-mainz-", parent) do |directory|
            result = prepare(program, directory, input.svg, input.style, dimensions)
            install(result, output)
          end
          output
        end

        def prepare(program, directory, svg, declaration, dimensions)
          source, definitions, result = %w[source.svg style.json output.pdf].map { ::File.join(directory, it) }
          ::File.binwrite(source, svg)
          ::File.write(definitions, declaration)
          run(program, "produce", source, "--declaration", definitions, "--output", result, *dimensions)
          result
        end

        def run(*arguments)
          process = F.sh(*arguments)
          raise ::Interrupt if Signal.list.values_at("INT", "TERM", "KILL").include?(process.signal) || process.exit_code == 130
          Error.("Mainz preparation failed: #{process.err}") unless process.ok?
          process
        rescue Errno::ENOENT => e
          Error.("Mainz executable is unavailable: #{e.message}")
        end

        def install(result, output)
          unless ::File.file?(result) && !::File.symlink?(result) && ::File.size(result).positive?
            Error.("Mainz produced no PDF")
          end
          ::FileUtils.mkdir_p(::File.dirname(output))
          ::File.rename(result, output)
        end
      end
    end
  end
end
