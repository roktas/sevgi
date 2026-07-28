+++
title = "Usage"
weight = 2
[extra]
group = "Start"
+++

Sevgi can run a drawing as an executable `.sevgi` program or build it inside a Ruby application. The drawing block is
the same in both forms; what changes is who provides the surrounding names and who owns the result. This page also
covers applications that need to execute complete, trusted Sevgi source.

## Choose a form

Use a script when the drawing is the program, such as a generated asset or build job. The runner supplies Sevgi's
top-level words, and the script usually ends with an [output operation](@/output.md):

```ruby
#!/usr/bin/env -S ruby -S sevgi

canvas = Canvas width: 24, height: 24, unit: :px

SVG :minimal, canvas do
  circle cx: 12, cy: 12, r: 10, fill: "tomato"
end.Save "badge.svg"
```

Use Sevgi as a library when another application owns the drawing and decides where its rendered string goes:

```ruby
require "sevgi"

canvas = SVG.Canvas width: 24, height: 24, unit: :px

drawing = SVG :minimal, canvas do
  circle cx: 12, cy: 12, r: 10, fill: "tomato"
end

File.write "badge.svg", drawing.Render
```

Operations around the document block are bare words in a script and capitalized methods on the `SVG` facade in
library code. Types and namespaces keep their double-colon spelling in both forms:

| Role | `.sevgi` script | Ruby library |
| --- | --- | --- |
| Build a document | `SVG(...)` | `SVG(...)` |
| Create a canvas | `Canvas(...)` | `SVG.Canvas(...)` |
| Refer to the canvas type | `SVG::Canvas` | `SVG::Canvas` |
| Create a callable module | `SVG.Module { ... }` | `SVG.Module { ... }` |

Both forms are ordinary Ruby. Use local variables, constants, methods, modules, loops, and data structures wherever
they make the drawing clearer.

## Scripts {#scripts}

A `.sevgi` file is ordinary Ruby run by the `sevgi` command. Before evaluating it, the runner installs Sevgi's DSL
words in the managed top-level scope. A typical script has a `ruby -S sevgi` shebang, any data or calculations the
drawing needs, and an `SVG` block followed by `Save`, `Write`, or `Out`.

Call `SVG`, SVG elements such as `rect` and `circle`, and operations such as `Canvas`, `Paper`, and `TileX` as plain DSL
words. The script needs neither `require "sevgi"` nor an `SVG.` prefix:

```ruby
Paper 85, 55, :card

SVG :minimal, :card do
  rect width: "100%", height: "100%", rx: 3
end.Save
```

The runner makes the full top-level API available both at the top of the file and inside helper classes. The document
operations are `SVG`, `Canvas`, `Document`, `Document!`, `Paper`, `Paper!`, `Mixin`,
`Grid`, and `Load`. Derender adds `Decompile`, `Derender`, `Evaluate`, and `EvaluateChildren`; append `File` to one of
those names when its input is a path. Drawing words such as `Rotate` live inside an `SVG` block. The
[DSL Catalog](@/dsl.md) records the context for every word.

### Load {#load}

`Load "palette"` evaluates `palette.sevgi` relative to the active source, not the process working directory. This lets
a drawing split across several files move as one directory. Repeated non-recursive loads run again; loading a source
already active in the same chain raises a captured cycle error.

If loading fails, the executor result keeps the source stack and points back to the file that caused it. Outside an
active Sevgi execution, use Ruby's `require` rather than `Load`.

### Rake {#rake}

Require `sevgi/binaries/rake` in a Rakefile to run a script without spawning a shell:

```ruby
require "sevgi/binaries/rake"

file "card.svg" => "card.sevgi" do
  sevgi "card", "front", theme: :dark
end
```

Positional arguments arrive as `ARGA`; keyword arguments arrive as `ARGH`.

## Libraries {#libraries}

`require "sevgi"` loads the global `SVG(...)` document builder and the `SVG` facade. Facade operations use
capitalized method names such as `SVG.Canvas`, `SVG.Document`, and `SVG.Derender`; constants and types use double
colons, such as `SVG::Canvas`. This keeps the full toolkit available without making every Sevgi helper a bare method
throughout the application.

### Facade grammar {#facade}

```ruby
require "sevgi"

canvas = SVG.Canvas width: 24, height: 24, unit: :px
drawing = SVG(:minimal, canvas) { circle cx: 12, cy: 12, r: 10 }

canvas.is_a?(SVG::Canvas) # => true
drawing.Render
```

`SVG(...)` invokes the global document builder. `SVG.Canvas(...)` invokes a facade operation, and `SVG::Canvas` names
the returned type. The facade does not repeat the name as `SVG.SVG(...)`.

Promoted operations also exist on `Sevgi` because script execution and `include Sevgi` use that complete set of
methods. `Sevgi.SVG(...)` and `Sevgi.Canvas(...)` are valid, but library code usually uses the shorter `SVG` facade.
Execution remains separate as `Sevgi.execute` and `Sevgi.execute_file`.

The script runner promotes operations such as `Paper`, `Canvas`, and `Grid` into its scope. Library code uses the same
capitalized words on the facade:

```ruby
require "sevgi"

SVG.Paper 85, 55, :card
canvas = SVG.Canvas :card, margins: 4

card = SVG :minimal, canvas do
  rect width: "100%", height: "100%", rx: 3
end

File.write "card.svg", card.Render
```

The equivalent script drops only the `SVG.` prefix. `Paper(...)` and `Canvas(...)` become bare words, while the
`SVG(...)` block stays unchanged.

### Import the top level

If a class is dedicated to drawing, include `Sevgi` and use the script-style names inside it:

```ruby
require "sevgi"

badge = Class.new do
  include Sevgi

  def render(label)
    SVG(:minimal) { text label, x: 4, y: 14 }.Render
  end
end

badge.new.render("S")
```

`include Sevgi` adds the full top-level API to instances. It is unnecessary when a class only calls the global
`SVG(...)` builder or uses facade operations.

### Focused components

Applications that depend only on `sevgi-graphics` use its conventional lowercase component API. This focused require
does not install the full `SVG` facade:

```ruby
require "sevgi/graphics"

canvas = Sevgi::Graphics.canvas width: 24, height: 24, unit: :px
drawing = Sevgi::Graphics.SVG(:minimal, canvas) { circle cx: 12, cy: 12, r: 10 }
```

Use this form when the smaller gem dependency is the goal. `SVG.Canvas` is the corresponding full-toolkit spelling.

## Execute source {#execute}

Use `Sevgi.execute` when trusted Ruby source needs the full script scope, or `Sevgi.execute_file` when that source
already lives in a `.sevgi` file. Both return a result instead of raising failures produced by the script.

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
`result.error.cause` is the original exception and `result.error.load_backtrace` keeps entries belonging to those
sources.

The public result types are `Sevgi::Executor::Result`, `Sevgi::Executor::Error`, and
`Sevgi::Executor::CycleError`.

### Source context

| Option | Meaning |
| --- | --- |
| `file:` | Diagnostic name and relative-load origin for inline source |
| `line:` | Starting line used in inline-source errors and backtraces |
| `as:` | Basename used by `execute_file` for evaluation, diagnostics, and caller-derived output defaults |
| `require:` | Ruby library loaded before the Sevgi source |
| `main: false` | Default isolated module scope; does not install the DSL on Ruby's main object |
| `main: true` | Command-line-compatible main-object mode for consumers that deliberately need it |

`execute_file` also accepts `as:`. Its extension becomes `.sevgi`, while the physical input directory and load-cycle
identity remain intact. An implicit output operation uses this logical name but still writes beside the input file.
Without `as:`, the input path supplies the evaluation name and starting line. Empty source without `require:` is a
strict no-op. Use the isolated default unless the application specifically needs command-line-compatible main-object
behavior.

Within active execution, `Load` resolves each file relative to the source that calls it:

```ruby
require "tmpdir"

Dir.mktmpdir do |dir|
  File.write File.join(dir, "palette.sevgi"), '@ink = "tomato"'
  File.write(
    File.join(dir, "icon.sevgi"),
    "Load 'palette'\nSVG(:minimal) { circle r: 4, fill: @ink }.Render\n"
  )

  result = Sevgi.execute_file File.join(dir, "icon.sevgi")
  raise result.error if result.error?
end
```

The isolated form keeps these top-level names out of the application, but it is not a security sandbox. Both methods
run trusted Ruby with the current process's file, network, and system authority. For SVG/XML input, use
[Derender](@/derender.md), whose public
conversion and inclusion APIs treat XML as data rather than executing the generated Ruby.
