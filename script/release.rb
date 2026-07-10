# frozen_string_literal: true

require "digest"
require "open3"
require "rubygems/package"

module SevgiRelease
  COMPONENT_ORDER = %w[
    sevgi-function
    sevgi-geometry
    sevgi-graphics
    sevgi-standard
    sevgi-derender
    sevgi-sundries
    sevgi
    sevgi-showcase
  ]
    .freeze

  module Preflight
    module_function

    VERSION_PATTERN = /\A\d+\.\d+\.\d+\z/
    def guard!(root:, ref:)
      version = read_version(root)
      raise_error("unsupported release ref: #{ref}") unless allowed_ref?(ref, version)

      validate_versions!(root, version)
      version
    end

    def allowed_ref?(ref, version)
      version.match?(VERSION_PATTERN) &&
        ["refs/heads/main", "refs/tags/v#{version}"].include?(ref)
    end

    def read_version(root)
      version = File.read(File.join(root, "VERSION")).strip
      raise_error("invalid VERSION: #{version.inspect}") unless version.match?(VERSION_PATTERN)

      version
    rescue Errno::ENOENT => e
      raise_error("missing VERSION: #{e.message}")
    end

    def validate_versions!(root, version)
      values = version_values(root)
      missing = values.select { |_file, value| value.nil? }.keys
      mismatches = values.reject { |_file, value| value == version }

      raise_error("missing version constants: #{missing.join(", ")}") unless missing.empty?
      unless mismatches.empty?
        details = mismatches.map { |file, value| "#{file}=#{value}" }.join(", ")
        raise_error("VERSION mismatch: #{details}")
      end

      values
    end

    def version_values(root)
      files = Dir[File.join(root, "*/lib/sevgi/**/version.rb")]
      raise_error("missing version constants") if files.empty?

      files.to_h do |file|
        [file, File.read(file)[/VERSION\s*=\s*"([^"]+)"/, 1]]
      end
    end

    def validate_archives!(root:, package_dir:, version:)
      Archive.validate!(root:, package_dir:, version:)
    end

    def assert_remote!(names:, version:, runner: method(:remote_query))
      names.each do |name|
        output, error, status = runner.call(name)
        raise_error("cannot query RubyGems for #{name}: #{error}") unless status.success?

        if output.match?(/\A#{Regexp.escape(name)} \((?=.*\b#{Regexp.escape(version)}\b)/)
          raise_error("#{name} #{version} is already published")
        end
      end
    end

    def preflight!(root:, ref:, package_dir:, remote_runner: method(:remote_query))
      version = guard!(root:, ref:)
      archives = validate_archives!(root:, package_dir:, version:)
      assert_remote!(names: archives.map { |archive| archive.fetch(:name) }, version:, runner: remote_runner)
      {version:, archives:}
    end

    def assert_checksums!(package_dir:, archives:, path: File.join(package_dir, "SHA256SUMS"))
      return unless File.file?(path)

      expected = checksum_entries(path)
      archives.each { |archive| assert_checksum!(archive, expected) }
    end

    def checksum_entries(path)
      File.readlines(path, chomp: true).to_h do |line|
        digest, relative = line.split("  ", 2)
        [relative, digest]
      end
    end

    def assert_checksum!(archive, expected)
      relative = File.basename(archive.fetch(:path))
      actual = Digest::SHA256.file(archive.fetch(:path)).hexdigest
      raise_error("checksum mismatch: #{relative}") unless expected.fetch(relative, nil) == actual
    end

    def publish!(root:, ref:, package_dir:, remote_runner: method(:remote_query), push: method(:push_gem))
      result = preflight!(root:, ref:, package_dir:, remote_runner:)
      assert_checksums!(package_dir:, archives: result.fetch(:archives))
      result.fetch(:archives).each { |archive| push.call(archive.fetch(:path)) }
      result
    end

    def gemspecs(root)
      specs = Dir[File.join(root, "*/*.gemspec")].map do |file|
        Gem::Specification.load(file) || raise_error("malformed gemspec: #{file}")
      end

      specs.sort_by { |spec| [COMPONENT_ORDER.index(spec.name) || COMPONENT_ORDER.length, spec.name] }
    end

    def remote_query(name)
      Open3.capture3("gem", "list", "--remote", "--exact", "--all", name)
    end

    def push_gem(path)
      output, error, status = Open3.capture3("gem", "push", path)
      raise_error("gem push failed for #{path}: #{error.empty? ? output : error}") unless status.success?
    end

    def raise_error(message)
      raise Error, message
    end

    module Archive
      module_function

      def validate!(root:, package_dir:, version:)
        specs = Preflight.gemspecs(root)
        Preflight.raise_error("no gemspecs found") if specs.empty?

        specs.map { |spec| validate_one(spec, package_dir:, version:) }
      end

      def validate_one(spec, package_dir:, version:)
        path = File.join(package_dir, "#{spec.name}-#{version}.gem")
        Preflight.raise_error("missing package: #{path}") unless File.file?(path)

        archive = load_archive(path, spec, version)
        validate_contents!(archive, path)

        {name: spec.name, path:, sha256: Digest::SHA256.file(path).hexdigest}
      rescue StandardError => e
        raise e if e.is_a?(Preflight::Error)

        Preflight.raise_error("#{path}: #{e.message}")
      end

      def validate_contents!(archive, path)
        files = archive.files
        Preflight.raise_error("empty package: #{path}") if files.empty?
        validate_paths!(files, path)
        validate_required_files!(files, path)
      end

      def load_archive(path, spec, version)
        archive = Gem::Package.new(path).spec
        Preflight.raise_error("malformed package name: #{path}") unless archive.name == spec.name
        Preflight.raise_error("malformed package version: #{path}") unless archive.version.to_s == version

        archive
      end

      def validate_paths!(files, path)
        invalid = files.grep(%r{\A(?:/|\.\./)|(?:^|/)\.agents(?:/|$)|(?:^|/)AGENTS\.md\z})
        Preflight.raise_error("invalid package contents in #{path}: #{invalid.join(", ")}") unless invalid.empty?
      end

      def validate_required_files!(files, path)
        %w[CHANGELOG.md LICENSE README.md].each do |required|
          Preflight.raise_error("missing #{required} in #{path}") unless files.include?(required)
        end
      end
    end

    class Error < StandardError
    end
  end
end

if $PROGRAM_NAME == __FILE__
  command, ref, package_dir = ARGV
  root = File.expand_path("..", __dir__)

  begin
    case command
    when "guard"
      SevgiRelease::Preflight.guard!(root:, ref: ref || ENV.fetch("GITHUB_REF"))
    when "preflight"
      SevgiRelease::Preflight.preflight!(root:, ref: ref || ENV.fetch("GITHUB_REF"), package_dir: package_dir || "pkg")
    else
      abort("usage: #{File.basename(__FILE__)} guard [ref] | preflight [ref] [package_dir]")
    end

  rescue SevgiRelease::Preflight::Error, KeyError, Errno::ENOENT => e
    warn(e.message)
    exit(1)
  end
end
