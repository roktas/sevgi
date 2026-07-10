# frozen_string_literal: true

require "digest"
require "open3"
require "rubygems/package"

module SevgiRelease
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
        (ref == "refs/heads/main" || ref == "refs/tags/v#{version}")
    end

    def read_version(root)
      version = File.read(File.join(root, "VERSION")).strip
      raise_error("invalid VERSION: #{version.inspect}") unless version.match?(VERSION_PATTERN)

      version
    rescue Errno::ENOENT => e
      raise_error("missing VERSION: #{e.message}")
    end

    def validate_versions!(root, version)
      files = Dir[File.join(root, "*/lib/sevgi/**/version.rb")].sort
      raise_error("missing version constants") if files.empty?

      values = files.to_h do |file|
        [file, File.read(file)[/VERSION\s*=\s*"([^"]+)"/, 1]]
      end

      missing = values.select { |_file, value| value.nil? }.keys
      mismatches = values.reject { |_file, value| value == version }

      raise_error("missing version constants: #{missing.join(", ")}") unless missing.empty?
      unless mismatches.empty?
        details = mismatches.map { |file, value| "#{file}=#{value}" }.join(", ")
        raise_error("VERSION mismatch: #{details}")
      end

      values
    end

    def validate_archives!(root:, package_dir:, version:)
      specs = gemspecs(root)
      raise_error("no gemspecs found") if specs.empty?

      specs.map do |spec|
        path = File.join(package_dir, "#{spec.name}-#{version}.gem")
        raise_error("missing package: #{path}") unless File.file?(path)

        package = Gem::Package.new(path)
        archive = package.spec
        raise_error("malformed package name: #{path}") unless archive.name == spec.name
        raise_error("malformed package version: #{path}") unless archive.version.to_s == version

        files = archive.files
        raise_error("empty package: #{path}") if files.empty?

        invalid = files.grep(%r{\A(?:/|\.\./)|(?:^|/)\.agents(?:/|$)|(?:^|/)AGENTS\.md\z})
        raise_error("invalid package contents in #{path}: #{invalid.join(", ")}") unless invalid.empty?

        %w[CHANGELOG.md LICENSE README.md].each do |required|
          raise_error("missing #{required} in #{path}") unless files.include?(required)
        end

        {name: spec.name, path:, sha256: Digest::SHA256.file(path).hexdigest}
      rescue StandardError => e
        raise e if e.is_a?(Error)

        raise_error("#{path}: #{e.message}")
      end
    end

    def validate_remote!(names:, version:, runner: method(:remote_query))
      names.each do |name|
        output, error, status = runner.call(name)
        raise_error("cannot query RubyGems for #{name}: #{error}") unless status.success?

        if output.match?(%r{\A#{Regexp.escape(name)} \((?=.*\b#{Regexp.escape(version)}\b)})
          raise_error("#{name} #{version} is already published")
        end
      end

      true
    end

    def preflight!(root:, ref:, package_dir:)
      version = guard!(root:, ref:)
      archives = validate_archives!(root:, package_dir:, version:)
      validate_remote!(names: archives.map { |archive| archive.fetch(:name) }, version:)
      {version:, archives:}
    end

    def gemspecs(root)
      Dir[File.join(root, "*/*.gemspec")].sort.map do |file|
        Gem::Specification.load(file) || raise_error("malformed gemspec: #{file}")
      end
    end

    def remote_query(name)
      Open3.capture3("gem", "list", "--remote", "--exact", "--all", name)
    end

    def raise_error(message)
      raise Error, message
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
