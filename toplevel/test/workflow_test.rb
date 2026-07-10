# frozen_string_literal: true

require "yaml"

require_relative "test_helper"

module Sevgi
  class WorkflowTest < Minitest::Test
    ROOT = File.expand_path("../..", __dir__)
    WORKFLOWS = Dir[File.join(ROOT, ".github/workflows/*.yml")].sort.freeze
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
  end
end
