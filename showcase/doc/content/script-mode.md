+++
title = "Script Mode"
weight = 2
[extra]
group = "Start"
+++

A `.sevgi` file is ordinary Ruby run by the `sevgi` command. Before evaluating the file, the runner installs Sevgi's DSL
words in the script's top-level scope.

Applications embedding the same runner should use the result-oriented [Execution](@/execution.md) API.

## Script shape

A typical script has:

- a shebang that runs `ruby -S sevgi`
- Ruby constants, helper classes, or calculations
- an `SVG` block followed by `Save`, `Write`, or `Out`

In the checkers example, a Ruby hash stores the piece positions. A callable module holds the drawing steps, and the
`SVG` block invokes them with `Call`.

Callable modules can put argument-independent SVG in `base` blocks. Sevgi runs inherited bases from parent to child,
then local bases in registration order. Name a single drawing method `call`; give multiple methods names that describe
their drawing steps.

{{ tabs(base="checkers", dir="../showcase") }}

## Output methods

`Save` writes next to the script with the same base name and an `.svg` extension. The showcase files use this form.

`Write(path)` writes to a specific destination.

`Out` prints SVG to standard output, which suits shell pipelines and tests.

## Top-level DSL scope

In a script, call `SVG`, SVG elements such as `rect` and `circle`, and capitalized operations such as `Canvas`, `Paper`,
and `TileX` as plain DSL words. There is little reason to spell out Sevgi's object graph in a file whose job is to draw.

It is still Ruby. Use hashes, loops, calculations, and helper objects wherever they make the drawing easier to read.

The runner installs the full top-level API in a managed scope. The script needs neither `require "sevgi"` nor an
`SVG.` facade receiver:

```ruby
Paper 85, 55, :card

SVG :minimal, :card do
  rect width: "100%", height: "100%", rx: 3
end.Save
```

Library code uses the same words through the facade: the example above becomes `SVG.Paper(...)` followed by the same
`SVG(...)` block. Types and callable-module contracts keep their double-colon spelling in both modes, such as
`SVG::Canvas` and `SVG::Module`.

## Load {#load}

`Load "palette"` evaluates `palette.sevgi` relative to the active script, not the process working directory. You can
move a drawing split across several files as one directory. If loading fails, the executor error keeps the source stack
and points back to the file that caused it.

## Top-level API {#top-level-api}

Script mode exposes the document entry points `SVG`, `Canvas`, `Document`, `Document!`, `Paper`, `Paper!`, `Mixin`,
`Grid`, and `Load`. Its Derender entry points are `Decompile`, `Derender`, `Evaluate`, and `EvaluateChildren`; append
`File` to any of those names when the input is a file path. Drawing words such as `Rotate` live inside an `SVG` block.
The [DSL Catalog](@/dsl.md) records the context for every word, including script-only helpers.

## Rake {#rake}

Require `sevgi/binaries/rake` in a Rakefile to run a script without spawning a shell:

```ruby
require "sevgi/binaries/rake"

file "card.svg" => "card.sevgi" do
  sevgi "card", "front", theme: :dark
end
```

Positional arguments arrive as `ARGA`; keyword arguments arrive as `ARGH`.
