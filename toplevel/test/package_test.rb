# frozen_string_literal: true

require "fileutils"
require "digest"
require "open3"
require "rbconfig"
require "rubygems/package"
require "tmpdir"

require_relative "test_helper"

module Sevgi
  class PackageTest < Minitest::Test
    ROOT = ::File.expand_path("../..", __dir__)
    VERSION = ::File.read(::File.join(ROOT, "VERSION")).strip
    MINIMUM_RUBY = "3.4.0"
    CLEAN_ENV = {
      "RUBYLIB" => nil,
      "RUBYOPT" => nil
    }.freeze
    Component = Data.define(:dir, :name, :entrypoint, :executables)
    COMPONENTS = [
      Component["function", "sevgi-function", "sevgi/function", []],
      Component["geometry", "sevgi-geometry", "sevgi/geometry", []],
      Component["graphics", "sevgi-graphics", "sevgi/graphics", []],
      Component["standard", "sevgi-standard", "sevgi/standard", []],
      Component["derender", "sevgi-derender", "sevgi/derender", %w[igves]],
      Component["sundries", "sevgi-sundries", "sevgi/sundries", []],
      Component["toplevel", "sevgi", "sevgi", %w[sevgi]],
      Component["showcase", "sevgi-showcase", "sevgi/showcase", []]
    ].freeze

    def test_archives_are_complete_from_root_and_component_builds
      Dir.mktmpdir do |dir|
        root_packages = build_root_packages(::File.join(dir, "root"))
        component_packages = build_component_packages(::File.join(dir, "components"))

        COMPONENTS.each do |component|
          assert_package_contents(root_packages.fetch(component.name), component)
          assert_package_contents(component_packages.fetch(component.name), component)
        end
      end
    end

    def test_root_build_is_independent_of_cwd
      Dir.mktmpdir do |dir|
        packages = build_root_packages(::File.join(dir, "pkg"), chdir: dir)

        COMPONENTS.each do |component|
          assert_package_contents(packages.fetch(component.name), component)
        end
      end
    end

    def test_archives_install_and_load_from_clean_gem_home
      Dir.mktmpdir do |dir|
        packages = build_root_packages(::File.join(dir, "pkg"))
        gem_home = ::File.join(dir, "gems")
        install_packages(packages, gem_home)

        smoke_installed_gems(gem_home)
        smoke_installed_cli(gem_home)
      end
    end

    def test_component_documents_are_canonical_and_substantive
      license = ::File.join(ROOT, "LICENSE")
      changelog = ::File.join(ROOT, "CHANGELOG.md")
      license_digest = ::Digest::SHA256.file(license).hexdigest
      changelog_digest = ::Digest::SHA256.file(changelog).hexdigest

      COMPONENTS.each do |component|
        component_license = ::File.join(ROOT, component.dir, "LICENSE")
        component_changelog = ::File.join(ROOT, component.dir, "CHANGELOG.md")

        assert_equal(license_digest, ::Digest::SHA256.file(component_license).hexdigest, component.name)
        assert_equal(changelog_digest, ::Digest::SHA256.file(component_changelog).hexdigest, component.name)
        assert_operator(::File.size(component_license), :>, 10_000, component.name)
        assert_includes(::File.read(component_changelog), "## 0.94.0", component.name)
      end
    end

    def test_gemspec_manifests_are_independent_of_cwd
      Dir.mktmpdir do |dir|
        [ROOT, dir].each do |cwd|
          Dir.chdir(cwd) do
            COMPONENTS.each do |component|
              path = ::File.join(ROOT, component.dir, "#{component.name}.gemspec")
              spec = ::Gem::Specification.load(path)

              assert_equal(component.name, spec.name)
              assert_includes(spec.files, "lib/#{component.entrypoint}/version.rb", component.name)
              refute(spec.files.any? { |file| file.start_with?("/", "../") }, component.name)
            end
          end
        end
      end
    end

    def test_component_readmes_are_self_contained
      COMPONENTS.each do |component|
        readme = ::File.read(::File.join(ROOT, component.dir, "README.md"))

        refute_includes(readme, "../", component.name)
        assert_includes(readme, "gem install #{component.name}", component.name)
        assert_includes(readme, "require \"#{component.entrypoint}\"", component.name)
        assert_includes(readme, "Native prerequisites", component.name)
        assert_includes(readme, "Ruby #{MINIMUM_RUBY} or newer", component.name)
        assert_includes(readme, "https://sevgi.roktas.dev", component.name)
        assert_includes(readme, "https://github.com/roktas/sevgi", component.name)
        assert_includes(readme, "https://www.rubydoc.info/gems/#{component.name}", component.name)
      end
    end

    def test_gemspec_ruby_floor_matches_documentation
      COMPONENTS.each do |component|
        gemspec = ::Gem::Specification.load(::File.join(ROOT, component.dir, "#{component.name}.gemspec"))

        assert_equal(">= #{MINIMUM_RUBY}", gemspec.required_ruby_version.to_s, component.name)
      end
    end

    def test_rake_clean_tasks_are_scoped
      assert_includes(::File.read(::File.join(ROOT, ".gitignore")), "/pkg/")
      assert_includes(::File.read(::File.join(ROOT, "Rakefile")), "task(:coverage)")

      root_pkg = ::File.join(ROOT, "pkg/agent-clean.tmp")
      root_coverage = ::File.join(ROOT, ".cache/ruby/coverage/agent-clean.tmp")
      component_pkg = ::File.join(ROOT, "function/pkg/agent-clean.tmp")
      component_coverage = ::File.join(ROOT, "function/coverage/agent-clean.tmp")

      [root_pkg, root_coverage, component_pkg, component_coverage].each do |file|
        ::FileUtils.mkdir_p(::File.dirname(file))
        ::File.write(file, "test")
      end

      run_rake("clean")
      run_rake("clean", chdir: ::File.join(ROOT, "function"))

      refute(::File.exist?(root_pkg))
      assert(::File.exist?(root_coverage))
      refute(::File.exist?(component_pkg))
      assert(::File.exist?(component_coverage))
    ensure
      ::FileUtils.rm_rf(::File.join(ROOT, "pkg"))
      ::FileUtils.rm_rf(::File.join(ROOT, "function/pkg"))
      ::FileUtils.rm_rf(::File.join(ROOT, "function/coverage"))
      ::FileUtils.rm_f(root_coverage) if root_coverage
    end

    def test_rake_tasks_use_portable_process_invocation
      root = ::File.read(::File.join(ROOT, "Rakefile"))
      component = ::File.read(::File.join(ROOT, "showcase/Rakefile"))

      assert_includes(root, "Open3.capture3(\"gem\", \"list\"")
      assert_includes(root, "sh(\"rake\", tn.to_s)")
      assert_includes(root, "sh(\"gem\", \"push\", gem)")
      assert_includes(component, "::File::PATH_SEPARATOR")
      assert_includes(component, "sh([t.source, t.source], verbose: false)")
      assert_includes(component, "sh(\"zola\", \"build\")")
      refute_includes(component, "ENV[\"PATH\"] += \":")
      refute_includes(component, "sh(\"\#{t.source}\"")
    end

    def test_release_preflight_checks_worktree_status
      rakefile = ::File.read(::File.join(ROOT, "Rakefile"))

      assert_includes(rakefile, "release:preflight")
      assert_includes(rakefile, "git\", \"status\", \"--short")
    end

    def test_test_workflow_covers_ruby_floor_and_development_ruby
      workflow = ::File.read(::File.join(ROOT, ".github/workflows/test.yml"))
      development_ruby = ::File.read(::File.join(ROOT, ".ruby-version")).strip

      assert_includes(workflow, "\"#{MINIMUM_RUBY}\"")
      refute_includes(workflow, "MINIMUM_RUBY.delete_suffix")
      assert_includes(workflow, "\"#{development_ruby}\"")
      assert_includes(workflow, "bundle exec rake test")
      assert_includes(workflow, "bundle exec rake build")
    end

    private

    def assert_package_contents(package, component)
      gem = ::Gem::Package.new(package)
      contents = gem.contents

      %w[CHANGELOG.md LICENSE README.md].each { assert_includes(contents, it, component.name) }
      assert_equal(
        ::Digest::SHA256.file(::File.join(ROOT, "LICENSE")).hexdigest,
        package_file_digest(package, "LICENSE"),
        component.name
      )
      assert_equal(
        ::Digest::SHA256.file(::File.join(ROOT, "CHANGELOG.md")).hexdigest,
        package_file_digest(package, "CHANGELOG.md"),
        component.name
      )
      assert_includes(contents, "lib/#{component.entrypoint}.rb", component.name)
      assert_includes(contents, "lib/#{component.entrypoint}/version.rb", component.name)
      component.executables.each { assert_includes(contents, "bin/#{it}", component.name) }
      assert_empty(contents.grep(%r{\A/|\.\.}), component.name)
      refute(contents.any? { |file| file == "AGENTS.md" || file.start_with?(".agents/") }, component.name)
      assert_equal(component.executables, gem.spec.executables.sort)
    end

    def build_component_package(component, dir)
      package = ::File.join(dir, "#{component.name}.gem")
      component_dir = ::File.join(ROOT, component.dir)

      ::FileUtils.mkdir_p(dir)
      capture_io do
        Dir.chdir(component_dir) do
          spec = ::Gem::Specification.load("#{component.name}.gemspec")
          ::Gem::Package.build(spec, true, false, package)
        end
      end

      package
    end

    def package_file_digest(package, path)
      ::Dir.mktmpdir do |dir|
        ::Gem::Package.new(package).extract_files(dir)
        ::Digest::SHA256.file(::File.join(dir, path)).hexdigest
      end
    end

    def build_component_packages(dir)
      COMPONENTS.to_h { [it.name, build_component_package(it, dir)] }
    end

    def build_root_packages(dir, chdir: ROOT)
      out, err, status = Open3.capture3(
        {"BUNDLE_GEMFILE" => ::File.join(ROOT, "Gemfile")},
        "bundle",
        "exec",
        "rake",
        "-f",
        ::File.join(ROOT, "Rakefile"),
        "build",
        "PKGDIR=#{dir}",
        chdir:
      )

      assert(status.success?, "stdout:\n#{out}\nstderr:\n#{err}")
      COMPONENTS.to_h { [it.name, ::File.join(dir, "#{it.name}-#{VERSION}.gem")] }
    end

    def run_rake(*args, chdir: ROOT)
      out, err, status = Open3.capture3("bundle", "exec", "rake", *args, chdir:)

      assert(status.success?, "stdout:\n#{out}\nstderr:\n#{err}")
    end

    def install_packages(packages, gem_home)
      args = [
        RbConfig.ruby,
        "-S",
        "gem",
        "install",
        "--no-document",
        "--local",
        "--force",
        "--install-dir",
        gem_home,
        "--bindir",
        ::File.join(gem_home, "bin"),
        "--no-user-install",
        "--ignore-dependencies",
        *COMPONENTS.map { packages.fetch(it.name) }
      ]

      out, err, status = Open3.capture3(clean_env.merge("GEM_HOME" => gem_home, "GEM_PATH" => gem_home), *args)
      assert(status.success?, "stdout:\n#{out}\nstderr:\n#{err}")
    end

    def clean_env
      CLEAN_ENV.merge(ENV.keys.grep(/\ABUNDLE|BUNDLER/).to_h { [it, nil] })
    end

    def smoke_env(gem_home)
      clean_env.merge(
        "GEM_HOME" => gem_home,
        "GEM_PATH" => ([gem_home] + ::Gem.path).join(::File::PATH_SEPARATOR),
        "PATH" => [::File.join(gem_home, "bin"), ENV.fetch("PATH")].join(::File::PATH_SEPARATOR)
      )
    end

    def smoke_installed_cli(gem_home)
      out, err, status = Open3.capture3(smoke_env(gem_home), "sevgi", "--version")

      assert(status.success?, "stdout:\n#{out}\nstderr:\n#{err}")
      assert_equal(VERSION, out.strip)
    end

    def smoke_installed_gems(gem_home)
      code = <<~RUBY
        require "sevgi"
        require "sevgi/showcase"

        %w[
          sevgi-function
          sevgi-geometry
          sevgi-graphics
          sevgi-standard
          sevgi-derender
          sevgi-sundries
          sevgi
          sevgi-showcase
        ].each do |name|
          spec = Gem.loaded_specs.fetch(name)
          raise "\#{name} loaded from \#{spec.full_gem_path}" unless spec.full_gem_path.start_with?(ENV.fetch("GEM_HOME"))
        end
      RUBY

      out, err, status = Open3.capture3(smoke_env(gem_home), RbConfig.ruby, "-e", code)
      assert(status.success?, "stdout:\n#{out}\nstderr:\n#{err}")
    end
  end
end
