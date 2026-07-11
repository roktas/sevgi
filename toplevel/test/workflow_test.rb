# frozen_string_literal: true

require "digest"
require "fileutils"
require "open3"
require "tmpdir"
require "yaml"

require_relative "test_helper"

module Sevgi
  class WorkflowTest < Minitest::Test
    ROOT = File.expand_path("../..", __dir__)
    WORKFLOWS = Dir[File.join(ROOT, ".github/workflows/*.yml")].freeze
    ACTION = /@[0-9a-f]{40}\z/

    def test_workflows_parse_and_pin_external_actions
      WORKFLOWS.each do |file|
        document = YAML.safe_load_file(file, aliases: true)
        assert_kind_of(Hash, document, file)

        File.read(file).scan(/^\s+uses:\s+([^\s]+)$/).flatten.each do |reference|
          assert_match(ACTION, reference, "unpinned action in #{file}: #{reference}")
        end
      end
    end

    def test_workflows_declare_read_only_permissions_by_default
      WORKFLOWS.each do |file|
        document = YAML.safe_load_file(file, aliases: true)
        global = document["permissions"]
        jobs = document.fetch("jobs")

        jobs.each do |name, job|
          permissions = job["permissions"] || global
          expected = name == "deploy" && file.end_with?("/site.yml") ? "write" : "read"
          assert_equal(expected, permissions.fetch("contents"), "unexpected permission for #{name} in #{file}")
        end
      end
    end

    def test_privileged_capabilities_are_limited_to_publishing_jobs
      ship = File.read(File.join(ROOT, ".github/workflows/ship.yml"))
      site = File.read(File.join(ROOT, ".github/workflows/site.yml"))

      assert_includes(ship, "environment: release")
      assert_includes(ship, "id-token: write")
      assert_includes(site, "environment: site")
      WORKFLOWS.reject { |file| file.end_with?("/ship.yml") }.each do |file|
        refute_includes(File.read(file), "id-token: write", file)
      end

      refute_includes(ship, "Gem::Package.new")
      assert_includes(File.read(File.join(ROOT, ".github/dependabot.yml")), "package-ecosystem: github-actions")
    end

    def test_ship_publish_uses_manifest_order
      Dir.mktmpdir do |dir|
        package_dir = File.join(dir, "pkg")
        bin = File.join(dir, "bin")
        log = File.join(dir, "pushes")
        FileUtils.mkdir_p([package_dir, bin])
        archives = %w[zeta-1.2.3.gem alpha-1.2.3.gem]

        File.write(
          File.join(bin, "gem"),
          <<~BASH
            #!/usr/bin/env bash
            set -Eeuo pipefail
            printf '%s\n' "$2" >> "$PUSH_LOG"
          BASH
        )
        FileUtils.chmod("+x", File.join(bin, "gem"))
        archives.each { File.write(File.join(package_dir, it), it) }
        checksums = archives.map { "#{Digest::SHA256.file(File.join(package_dir, it)).hexdigest}  #{it}" }
        File.write(File.join(package_dir, "SHA256SUMS"), "#{checksums.join("\n")}\n")

        script = File.join(dir, "publish")
        File.write(script, "#!/usr/bin/env bash\n#{ship_publish_script}")
        FileUtils.chmod("+x", script)
        env = {"PATH" => "#{bin}:#{ENV.fetch("PATH")}", "PUSH_LOG" => log}
        out, err, status = Open3.capture3(env, script, chdir: dir)

        assert(status.success?, "stdout:\n#{out}\nstderr:\n#{err}")
        assert_equal(archives.map { "pkg/#{it}" }, File.readlines(log, chomp: true))

        FileUtils.rm(log)
        File.write(File.join(package_dir, "extra-1.2.3.gem"), "extra")
        _out, _err, status = Open3.capture3(env, script, chdir: dir)

        refute(status.success?)
        refute_path_exists(log)

        FileUtils.rm(File.join(package_dir, "extra-1.2.3.gem"))
        File.write(File.join(package_dir, archives.first), "tampered")
        _out, _err, status = Open3.capture3(env, script, chdir: dir)

        refute(status.success?)
        refute_path_exists(log)
      end
    end

    private

    def ship_publish_script
      workflow = YAML.safe_load_file(File.join(ROOT, ".github/workflows/ship.yml"), aliases: true)
      step = workflow.fetch("jobs").fetch("publish").fetch("steps").find { |candidate|
        candidate["name"] == "Verify and push packages 💎"
      }

      step.fetch("run")
    end
  end
end
