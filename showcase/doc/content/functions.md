+++
title = "Functions"
weight = 15
[extra]
group = "Toolkit"
+++

`Sevgi::F` is the supported toolbox shared by Sevgi components and advanced extensions. Check it before reimplementing
Sevgi-specific numeric, discovery, command, naming, or status behavior. It is deliberately smaller than a
general-purpose utility library.

| Need | Start with | Result or configuration |
| --- | --- | --- |
| Degree-based trigonometry and approximate comparison | `sin`, `cos`, `eq?`, `approx`, `with_precision` | `Function::Math.precision` is thread-local |
| Find a `.sevgi` file while walking upward | `locate` or configurable `Function::Locate` | immutable `Function::Location` |
| Compare or write generated files | `changed?`, `out`, `touch` | path or change status |
| Run an argv-safe child process | `sh` or success-requiring `sh!` | immutable `Function::Shell::Result` |
| Build Sevgi-facing names | `demodulize`, `pluralize` | string |
| Report build progress | `do`, `mayok`, `ok`, `notok`, `ui` | status on standard error |

In ordinary library code, spell the facade as `Sevgi::F`. Bare `F` is available to `.sevgi` scripts and to receivers
that explicitly include the top-level DSL; it is not a global constant installed by `require "sevgi/function"`.

## Numeric work

Angles are in degrees. Precision belongs to the current thread; prefer `with_precision` for a temporary policy or pass
`precision:` to one comparison.

```ruby
Sevgi::F.with_precision(3) do
  Sevgi::F.cos(60)     # degree-based trigonometry
  Sevgi::F.approx(1.0 / 3)
end
```

## Commands

`sh` receives argv entries, not a shell command string. It captures both streams and returns a result even when the
program exits unsuccessfully. Use `sh!` when failure should raise `Sevgi::Error`.

```ruby
require "rbconfig"

result = Sevgi::F.sh(RbConfig.ruby, "-e", 'warn "invalid"; exit 3')
raise unless result.notok?
raise unless result.exit_code == 3
raise unless result.err == "invalid"
```

## File discovery

`locate` qualifies an extensionless name as `.sevgi` and searches from the given directory toward the filesystem root.
The returned location records both the matching file and the directory that supplied it.

```ruby
require "fileutils"

FileUtils.mkdir_p("project/drawings")
File.write("project/palette.sevgi", "COLORS = %w[black white]\n")

location = Sevgi::F.locate("palette", "project/drawings")
raise unless location.slug == "palette.sevgi"
raise unless location.dir == File.expand_path("project")
```

Use `Function::Locate` directly when an extension should not be added, several candidates are acceptable, or exclusions
and a custom matcher are needed. The [API reference](https://www.rubydoc.info/gems/sevgi-function) documents the facade
methods, returned values, and their failure contracts.
