+++
title = "Script Mode"
weight = 2
+++

Script mode is the normal way to use Sevgi. A `.sevgi` file is Ruby executed by the `sevgi` command, with the DSL words
installed in the script's top-level scope.

## Script Shape

A script usually has three parts:

- a shebang that runs `ruby -S sevgi`
- Ruby constants, helper classes, or calculations
- an `SVG` block followed by `Save`, `Write`, or `Out`

The checker-board example shows the pattern clearly: a regular Ruby hash stores the piece positions, while a callable
drawing module groups receiver-free DSL steps that the `SVG` block invokes with `Call`.

Callable drawing modules use `base` blocks for argument-independent SVG shared by their public drawing methods. Each
invocation runs inherited bases parent-first, then local bases in registration order. Name the drawing method `call` when
a module has only one; use descriptive method names when each of several methods represents a separate drawing step.

{{ tabs(base="checker-board", dir="../showcase") }}

## Output Methods

Use `Save` when the script should write next to itself using the same base name and the `.svg` extension. This is the
showcase convention.

Use `Write(path)` when the destination should be explicit.

Use `Out` when the script should print SVG to standard output. This is useful for shell pipelines and tests.

## Top-Level DSL Scope

In script mode, `SVG`, SVG element methods such as `rect` and `circle`, and helper methods such as `TileX` are intended
to be used as DSL words. Prefer that style in scripts instead of treating Sevgi primarily as a library object graph.

Ruby code is still available when the drawing needs data structures, loops, calculations, or small helper objects.
