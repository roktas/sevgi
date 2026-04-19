# Sevgi Codebase Guide for AI Coding Agents

This file applies to the whole repository unless a nested `AGENTS.md` overrides it.

SEVGI is a Ruby toolkit for creating SVG content programmatically through a DSL. In a nutshell:

```ruby
SVG :minimal do
  g id: "group" do
    rect   id: "rectangular", width: 3, height: 5
    circle id: "circle", r: 1
  end
end
```

SEVGI can also run `.sevgi` scripts directly:

```ruby
#!/usr/bin/env -S ruby -S sevgi

SVG do
  rect width: 3, height: 5
end.Out
```

See [Showcase](showcase/srv) for examples and output.

## Repository Map

The repository is a multi-gem Ruby project. Each component has its own gemspec, library code, and tests.

- `graphics`: Core DSL implementation. SVG elements are produced through `method_missing`; DSL helper methods are mixed
  in from `lib/sevgi/graphics/mixtures`.
- `standard`: SVG element and attribute validation against the SVG standard.
- `function`: General helper methods shared across components, usually available through `F`.
- `geometry`: Small geometry helpers for cases where relying on the SVG renderer is not enough.
- `derender`: Converts SVG/XML content back into Sevgi DSL Ruby code.
- `sundries`: Cross-component helper objects and tools, including export helpers.
- `toplevel`: Top-level API and script-mode execution support, including `bin/sevgi` and `lib/sevgi/executor`.
- `showcase`: Example `.sevgi` files, rendered outputs, and the documentation site.

### Some Useful Paths

- `Gemfile` and `Gemfile.lock`: Root bundle for all components.
- `Rakefile`: Defines root tasks such as `test`, `lint`, and component-scoped task forwarding.
- `<component>/lib`: Runtime code for that component.
- `<component>/test`: Minitest tests for that component.
- `showcase/srv`: Source examples and expected rendered outputs used by integration tests.
- `showcase/doc`: Documentation site. This subtree has its own `AGENTS.md`; read it before editing files there.

## Testing

The test suite uses Minitest. Use the narrowest command that covers the change, then broaden if the touched code is
shared.

### Test Placement

Mirror the runtime file path under the component's `test` tree, and put the test class in the same namespace as the code
under test.

For example, tests for:

```text
graphics/lib/sevgi/graphics/mixtures/render.rb
```

belong in:

```text
graphics/test/graphics/mixtures/render_test.rb
```

with a test class under `Sevgi::Graphics::Mixtures`, such as:

```ruby
module Sevgi
  module Graphics
    module Mixtures
      class RenderTest < Minitest::Test
      end
    end
  end
end
```

### Table-Driven Assertions

Avoid creating many tiny test methods when the cases exercise the same behavior. Prefer a small table inside one focused
test method, using the existing `each_slice(2)` style for expected/actual pairs.

Example:

```ruby
[
  1, doc.children.size,
  2, doc.children[0].children.size,
  0, doc.children[0].children[0].children.size
].each_slice(2) { |expected, actual| assert_equal(expected, actual) }
```

### Validation Commands

Run all tests for one component from the repository root:

```bash
bundle exec rake graphics:test
bundle exec rake sundries:test
```

Run all tests:

```bash
bundle exec rake test
```

Run one test file:

```bash
cd graphics && bundle exec ruby -Ilib:test test/graphics/document_test.rb
```

Run one named test:

```bash
cd graphics && bundle exec ruby -Ilib:test test/graphics/document_test.rb --name test_class_relations
```

Run lint for one component:

```bash
bundle exec rake graphics:lint
```

Run all lint checks:

```bash
bundle exec rake lint
```

## Conventions

- Write `CHANGELOG.md` entries according to the [Keep a Changelog](https://keepachangelog.com/) standard.
- Write commit messages according to the [Conventional Commits](https://www.conventionalcommits.org/) standard. Use the
  relevant skill instructions when preparing commits.
- Prefer component-scoped changes. If a helper is only useful in one component, keep it in that component rather than
  promoting it to `function` or `sundries`.

## Development Notes

- Native export code in `sundries` depends on Cairo/RSVG-related system libraries. CI installs these before Bundler.
- Releases are published from GitHub Releases, not from plain tag pushes. Publishing a GitHub Release triggers
  `.github/workflows/release.yml`, which uses `rubygems/release-gem`.
- The root `rake release` task publishes all component gems in dependency order. Make sure every published gem has a
  matching RubyGems Trusted Publisher entry for `.github/workflows/release.yml`.
- Keep `rubygems/release-gem` attestations disabled unless the OpenSSL/Bundler default-gem conflict has been resolved.
- When changing export behavior, run at least `bundle exec rake sundries:test`.
- When changing DSL rendering behavior, run the owning component tests and consider `bundle exec rake showcase:test`
  because showcase examples catch rendered-output regressions.
- Do not edit generated or expected rendered artifacts unless the task explicitly requires updating them. If generated
  outputs change intentionally, mention the source command or test that produced them.
- For SVG standard behavior, use MDN SVG documentation and the official W3C SVG specification as references.
