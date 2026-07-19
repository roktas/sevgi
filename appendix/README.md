# Sevgi Appendix

Sevgi Appendix packages development extras for the Sevgi SVG DSL: an agent skill and RuboCop rules for readable
`.sevgi` source. Installing the umbrella `sevgi` gem installs the matching Appendix version. A project that only needs
the development extras can install this package separately:

```sh
gem install sevgi-appendix
```

## Require

The package version is available without loading RuboCop:

```ruby
require "sevgi/appendix"
```

## Agent skill

For a complete user installation, install Sevgi with Homebrew on macOS or Linux:

```sh
brew install roktas/tap/sevgi
```

Locate the skill without guessing a Homebrew prefix or Cellar version:

```sh
sevgi --skill
```

The command prints one validated absolute path and nothing else. It fails if the installed `sevgi-appendix` version
does not match Sevgi or its `SKILL.md` is missing. Homebrew reports a stable path below its `opt` tree, so an agent's
skill directory may safely link to it. Homebrew keeps that path current across upgrades.

Coding agents look for skills in different directories. Paste this prompt into the agent you want to configure:

> Run `sevgi --skill`. Install the reported directory as a user-level skill named `sevgi` using this agent product's
> supported skill location. Use a symbolic link because this is a stable Homebrew path. Report the destination and
> whether a new session is required.

When the umbrella `sevgi` gem was installed through RubyGems or Bundler, the same query works, including inside a
bundle:

```sh
bundle exec sevgi --skill
```

Gem paths contain the package version and can disappear after an upgrade. Copy the complete reported directory into
the agent's skill location instead of keeping a long-lived symbolic link, then repeat the copy after updating Sevgi.
The skill uses progressive disclosure to route an agent through the DSL, SVG rendering semantics, Geometry and
Sundries helpers, Derender, and output workflows.

## RuboCop

Add the gem to development dependencies when the umbrella gem is not already present:

```ruby
gem "sevgi-appendix", require: false
```

Then enable the plugin in `.rubocop.yml`:

```yaml
plugins:
  - sevgi-appendix
```

Run RuboCop through the application's bundle:

```sh
bundle exec rubocop
```

The plugin adds `*.sevgi` files to RuboCop and checks the DSL's deliberate source shape: optional parentheses are
omitted from statement-like calls, one-line blocks use braces, multiline blocks use `do`/`end`, and strings use double
quotes. Parentheses remain valid where Ruby needs them or they clarify a compact chained expression.

### With rubyfmt

`rubyfmt` remains authoritative for ordinary Ruby. Keep `.sevgi` files hand-formatted and let Sevgi Appendix inspect
their DSL-specific shape:

```yaml
inherit_gem:
  rubocop-rubyfmt:
    - config/full.yml

plugins:
  - rubocop-rubyfmt
  - sevgi-appendix
```

Add the scripts to `.rubyfmtignore` so `rubyfmt` does not erase the shape the plugin protects:

```text
*.sevgi
**/*.sevgi
```

## Ruby compatibility

Requires Ruby 3.4.0 or newer. CI verifies Ruby 3.4.0 and the current development Ruby from `.ruby-version`.

## Native prerequisites

This gem needs only Ruby and its Ruby dependencies.

## Links

- Documentation: https://sevgi.roktas.dev
- API documentation: https://www.rubydoc.info/gems/sevgi-appendix
- Source: https://github.com/roktas/sevgi/tree/main/appendix
- Changelog: https://github.com/roktas/sevgi/blob/main/CHANGELOG.md
