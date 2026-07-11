# frozen_string_literal: true

require "json"
require "open3"
require "rake"
require "rbconfig"
require "tmpdir"

require_relative "test_helper"

load(File.expand_path("../../Rakefile", __dir__)) unless defined?(SevgiBuild)

module Sevgi
  class RakefileTest < Minitest::Test
    Build = ::SevgiBuild
    Manifest = ::SevgiRelease::Manifest
    Preflight = ::SevgiRelease::Preflight
    ROOT = File.expand_path("../..", __dir__)
    Status = Data.define(:success?)

    def test_load_keeps_helpers_off_object
      code = <<~RUBY
        require "digest"
        require "fileutils"
        require "json"
        require "open3"
        require "rubygems/package"
        require "zlib"

        before = Object.instance_methods(false) + Object.private_instance_methods(false)
        load ARGV.fetch(0)
        added = Object.instance_methods(false) + Object.private_instance_methods(false) - before
        abort("Object methods added: \#{added.sort.join(", ")}") unless added.empty?
      RUBY

      _output, error, status = Open3.capture3(
        RbConfig.ruby,
        "-rrake",
        "-e",
        code,
        File.join(ROOT, "Rakefile"),
        chdir: ROOT
      )

      assert(status.success?, error)
    end

    def test_workspace_rejects_status_failures_and_changes
      cases = [
        [["", "cannot run", Status.new(false)], /Cannot inspect git status/],
        [[" M Rakefile\n", "", Status.new(true)], /Worktree is not clean/]
      ]

      cases.each do |result, message|
        error = assert_raises(RuntimeError) do
          Build::Workspace.clean!(runner: -> (*_args) { result })
        end

        assert_match(message, error.message)
      end
    end

    def test_workspace_requires_main_branch
      cases = [
        [["", "cannot run", Status.new(false)], /Cannot inspect git branch/],
        [["review\n", "", Status.new(true)], /requires the main branch/]
      ]

      cases.each do |result, message|
        error = assert_raises(RuntimeError) do
          Build::Workspace.main!(runner: -> (*_args) { result })
        end

        assert_match(message, error.message)
      end
    end

    def test_workspace_accepts_clean_main_checkout
      clean = ["", "", Status.new(true)]
      main = ["main\n", "", Status.new(true)]

      assert_nil(Build::Workspace.clean!(runner: -> (*_args) { clean }))
      assert_nil(Build::Workspace.main!(runner: -> (*_args) { main }))
    end

    def test_docs_build_clears_cache_before_yard
      calls = []

      Build::Docs.build!(
        root: ROOT,
        remover: -> (path) { calls << [:remove, path] },
        runner: -> (*args) { calls << [:run, *args] }
      )

      assert_equal(
        [
          [:remove, File.join(ROOT, ".cache/ruby/doc/api")],
          [:remove, File.join(ROOT, ".cache/ruby/yardoc")],
          [:run, "yard", "doc", "--fail-on-warning"]
        ],
        calls
      )
    end

    def test_docs_verify_rejects_incomplete_stats
      cases = [
        [["", "yard failed", Status.new(false)], /YARD stats failed/],
        [["Methods: 2 (1 undocumented)\n", "", Status.new(true)], /Undocumented public API/]
      ]

      cases.each do |result, message|
        error = assert_raises(RuntimeError) do
          Build::Docs.verify!(root: ROOT, runner: -> (*_args) { result }, reporter: -> (_output) { })
        end

        assert_match(message, error.message)
      end
    end

    def test_docs_verify_reports_complete_stats
      reports = []
      result = ["Methods: 2 (0 undocumented)\n", "", Status.new(true)]

      output = Build::Docs.verify!(
        root: ROOT,
        runner: -> (*_args) { result },
        reporter: -> (text) { reports << text }
      )

      assert_equal(result.first, output)
      assert_equal([result.first], reports)
    end

    def test_docs_verify_rejects_exposed_private_pages
      Dir.mktmpdir do |root|
        page = File.join(root, ".cache/ruby/doc/api/Sevgi/Executor/Scope.html")
        FileUtils.mkdir_p(File.dirname(page))
        File.write(page, "private")
        result = ["Methods: 2 (0 undocumented)\n", "", Status.new(true)]

        error = assert_raises(RuntimeError) do
          Build::Docs.verify!(root:, runner: -> (*_args) { result }, reporter: -> (_output) { })
        end

        assert_includes(error.message, page)
      end
    end

    def test_docs_verify_accepts_hidden_private_pages
      Dir.mktmpdir do |root|
        result = ["Methods: 2 (0 undocumented)\n", "", Status.new(true)]

        assert_equal(
          result.first,
          Build::Docs.verify!(root:, runner: -> (*_args) { result }, reporter: -> (_output) { })
        )
      end
    end

    def test_coverage_calculates_lines_and_branches
      with_report(
        "/project/a.rb" => {
          "lines" => [1, 0, nil],
          "branches" => [{"coverage" => 1}, {"coverage" => 0}]
        },
        "/project/empty.rb" => {"lines" => [], "branches" => []}
      ) do |report|
        assert_equal({line: 50.0, branch: 50.0}, Build::Coverage.totals(report))
        assert_equal(["/project/a.rb", "/project/empty.rb"], Build::Coverage.files(report))
      end
    end

    def test_coverage_treats_empty_totals_as_complete
      with_report("/project/empty.rb" => {"lines" => [], "branches" => []}) do |report|
        assert_equal({line: 100.0, branch: 100.0}, Build::Coverage.totals(report))
      end
    end

    def test_coverage_rejects_missing_files_and_low_totals
      with_report("/project/a.rb" => {"lines" => [1], "branches" => []}) do |report|
        missing = assert_raises(RuntimeError) do
          Build::Coverage.require_files!(report, ["/project/a.rb", "/project/b.rb"])
        end

        assert_includes(missing.message, "/project/b.rb")

        low = assert_raises(RuntimeError) do
          Build::Coverage.require_floors!({line: 99.0, branch: 75.0}, {line: 99.0, branch: 80.0})
        end

        assert_match(/branch: 75\.00% < 80\.00%/, low.message)
      end
    end

    def test_coverage_accepts_complete_files_and_totals
      with_report("/project/a.rb" => {"lines" => [1], "branches" => []}) do |report|
        assert_nil(Build::Coverage.require_files!(report, ["/project/a.rb"]))
        assert_nil(Build::Coverage.require_floors!({line: 99.0, branch: 80.0}, {line: 99.0, branch: 80.0}))
      end
    end

    def test_lint_task_includes_root_rakefile
      assert_includes(Rake::Task[:lint].prerequisites, "lint:root")
    end

    def test_component_and_root_tasks_use_argv
      commands = []

      rake_main.stub(:sh, -> (*args) { commands << args }) do
        capture_io do
          invoke_actions(Rake::Task["function:lint"])
          invoke_actions(Rake::Task["function:package"])
          invoke_actions(Rake::Task["lint:root"])
        end
      end

      assert_equal(%w[rake lint], commands.fetch(0))
      assert_equal(%w[gem build sevgi-function.gemspec --output], commands.fetch(1).first(4))
      assert_match(%r{/pkg/sevgi-function-[\d.]+\.gem\z}, commands.fetch(1).last)
      assert_equal(%w[bundle exec rubocop Rakefile --display-cop-names], commands.fetch(2))
    end

    def test_release_guard_task_propagates_failure
      task = Rake::Task["release:guard"]
      failure = Preflight::Error.new("guard failed")

      with_env("GITHUB_REF" => "refs/heads/main") do
        Preflight.stub(:guard!, -> (**) { raise failure }) do
          assert_same(failure, assert_raises(Preflight::Error) { invoke(task) })
        end
      end
    end

    def test_release_verify_writes_validated_manifest
      task = Rake::Task["release:verify"]
      result = {version: "1.2.3", archives: [{name: "demo", path: "/demo.gem"}]}
      written = nil

      with_env("GITHUB_REF" => "refs/heads/main") do
        Preflight.stub(:preflight!, -> (**) { result }) do
          Manifest.stub(:write!, -> (**kwargs) { written = kwargs }) do
            invoke(task)
          end
        end
      end

      assert_equal(result.fetch(:archives), written.fetch(:archives))
    end

    def test_release_preflight_propagates_workspace_failure
      task = Rake::Task["release:preflight"]
      failure = RuntimeError.new("dirty")

      Build::Workspace.stub(:clean!, -> { raise failure }) do
        assert_same(failure, assert_raises(RuntimeError) { invoke(task) })
      end
    end

    def test_release_preflight_wires_build_and_manifest
      task = Rake::Task["release:preflight"]
      build = Rake::Task[:build]
      result = {version: "1.2.3", archives: [{name: "demo", path: "/demo.gem"}]}
      calls = []

      Build::Workspace.stub(:clean!, -> { calls << :clean }) do
        Build::Workspace.stub(:main!, -> { calls << :main }) do
          build.stub(:invoke, -> { calls << :build }) do
            Preflight.stub(
              :preflight!,
              -> (**) {
                calls << :preflight
                result
              }
            ) do
              Manifest.stub(:write!, -> (**) { calls << :manifest }) do
                invoke_actions(task)
              end
            end
          end
        end
      end

      assert_equal(%i[clean main build preflight manifest], calls)
    end

    def test_release_task_checksums_before_push
      task = Rake::Task[:release]
      result = {version: "1.2.3", archives: [{name: "demo", path: "/demo.gem"}]}
      calls = []

      Preflight.stub(
        :preflight!,
        -> (**) {
          calls << :preflight
          result
        }
      ) do
        Manifest.stub(:assert!, -> (**) { calls << :manifest }) do
          Build::Workspace.stub(:clean!, -> { calls << :clean }) do
            rake_main.stub(:sh, -> (*args) { calls << args }) do
              invoke_actions(task)
            end
          end
        end
      end

      assert_equal([:preflight, :manifest, ["gem", "push", "/demo.gem"], :clean], calls)
    end

    def test_coverage_check_wires_report_validations
      task = Rake::Task["coverage:check"]
      totals = {line: 99.0, branch: 88.0}
      calls = []

      Build::Coverage.stub(:require_files!, -> (*_args) { calls << :files }) do
        Build::Coverage.stub(
          :totals,
          -> (_report) {
            calls << :totals
            totals
          }
        ) do
          Build::Coverage.stub(:require_floors!, -> (value) { calls << [:floors, value] }) do
            capture_io { invoke_actions(task) }
          end
        end
      end

      assert_equal([:files, :totals, [:floors, totals]], calls)
    end

    def test_doc_check_task_wires_all_validations
      task = Rake::Task["doc:check"]
      calls = []

      Build::Docs.stub(:build!, -> (**) { calls << :build }) do
        Build::Docs.stub(:verify!, -> (**) { calls << :verify }) do
          invoke(task)
        end
      end

      assert_equal(%i[build verify], calls)
    end

    private

    def invoke(task)
      task.reenable
      task.invoke
    ensure
      task.reenable
    end

    def invoke_actions(task)
      task.actions.each { it.call(task) }
    end

    def rake_main = TOPLEVEL_BINDING.eval("self")

    def with_env(values)
      previous = values.to_h { |key, _value| [key, ENV.fetch(key, nil)] }
      values.each { |key, value| ENV[key] = value }
      yield
    ensure
      previous.each { |key, value| ENV[key] = value }
    end

    def with_report(coverage)
      Dir.mktmpdir do |dir|
        report = File.join(dir, "coverage.json")
        File.write(report, JSON.generate("coverage" => coverage))
        yield report
      end
    end
  end
end
