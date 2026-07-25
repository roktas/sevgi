+++
title = "Execution"
weight = 4
[extra]
group = "Start"
+++

Use `Sevgi.execute` when trusted Ruby source needs the full Sevgi script scope, or `Sevgi.execute_file` when that source
already lives in a `.sevgi` file. Both return a result instead of raising failures produced by the script.

## Inspect the result

```ruby
result = Sevgi.execute(
  'SVG(:minimal) { circle r: 4 }.Render',
  file: "inline-icon.sevgi",
  line: 12
)

if result.success?
  svg = result.value
else
  warn result.error.message
end
```

`success?` and `error?` describe the outcome. `value` is the last expression on success; `error` is an
`Executor::Error` on failure; `stack` is the immutable list of visited Sevgi sources. For diagnostics,
`result.error.cause` is the original exception and `result.error.load_backtrace` keeps backtrace entries belonging to
those sources.

The public observable types are `Sevgi::Executor::Result`, `Sevgi::Executor::Error`, and
`Sevgi::Executor::CycleError`. The custom receiver and boot runner beneath the two `Sevgi` entrypoints is internal.

## Source context

| Option | Meaning |
| --- | --- |
| `file:` | Diagnostic name and relative-load origin for inline source |
| `line:` | Starting line used in inline-source errors and backtraces |
| `as:` | Basename used by `execute_file` for evaluation, diagnostics, and caller-derived output defaults |
| `require:` | Ruby library loaded before the Sevgi source |
| `main: false` | Default isolated module scope; does not install the DSL on Ruby's main object |
| `main: true` | Command-line-compatible main-object mode for consumers that deliberately need it |

`execute_file` also accepts `as:`. Its extension becomes `.sevgi`, while the physical input directory and load-cycle
identity remain intact:

```ruby
result = Sevgi.execute_file("drawings/card.sevgi", as: "proof")
```

An implicit `Save` in that source writes `drawings/proof.svg`; relative `Load` calls still start in `drawings`.
Without `as:`, the input path supplies the evaluation name and starting line. Empty source without `require:` is a
strict no-op. Use the isolated default unless compatibility with command-line top-level behavior is the actual
requirement.

## Nested Load

Within an active execution, `Load` resolves `.sevgi` files relative to the source that calls it:

```ruby
require "tmpdir"

Dir.mktmpdir do |dir|
  File.write(File.join(dir, "palette.sevgi"), '@ink = "tomato"')
  File.write(
    File.join(dir, "icon.sevgi"),
    "Load 'palette'\nSVG(:minimal) { circle r: 4, fill: @ink }.Render\n"
  )

  result = Sevgi.execute_file(File.join(dir, "icon.sevgi"))
  raise result.error if result.error?
end
```

Repeated non-recursive loads run again. Loading a source already active in the same chain produces a captured
`CycleError`; inspect the result stack and `load_backtrace` to locate the cycle. Outside active execution, use Ruby's
`require` rather than `Load`.

## Trust boundary

Execution isolation is namespace hygiene, not a security sandbox. Both entrypoints run trusted Ruby with the current
process's file, network, and system authority. For SVG/XML input, use [Derender](@/derender.md): its public conversion
and inclusion APIs treat XML as data, so callers do not evaluate the generated Ruby source themselves.
