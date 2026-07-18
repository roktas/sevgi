+++
title = "Supported Usage"
weight = 21
[extra]
group = "More"
+++

Sevgi supports two public workflows: `.sevgi` scripts and Ruby library calls. You can rely on the DSL and components
described in this guide, along with the examples that the test suite runs. Internal helpers may change without notice.

## What is stable

The public API consists of the documented DSL and component methods. The runnable examples show how those pieces fit
together. Start there if you are unsure about a task: the examples are short enough to take apart, and the test suite
executes them against the current source.

Prefer documented DSL words in scripts: `SVG`, SVG element names, and helper methods such as `TileX`. Regular Ruby code
belongs around the DSL when the drawing needs loops, data structures, calculations, or small helper objects.

The generated [API reference](https://www.rubydoc.info/gems/sevgi) covers component-level Ruby APIs. This guide is the
better reference for scripts and drawing tasks.

Advanced extensions may rely on the documented `Sevgi::F` facade and the public values it returns. The supported
secondary Function surface is `Sevgi::Function::Location`, `Locate`, `Shell::Result`, and the thread-local
`Math.precision` accessors. Other nested Function modules organize the implementation and are not consumer
`include`/`extend` contracts.

## Outside the public API

Implementation details are not public API. Avoid depending on private constants, registry internals, generated helper
classes, cache state, or undocumented method aliases.

If the docs and examples do not cover a behavior, first check whether a direct SVG element will do the job. Otherwise,
the missing piece may need a documented helper and a test before scripts can safely depend on it.

## Version choice

Pin the Sevgi version when generated documents must be reproducible. The current source tree is fine for experiments,
but inspect the SVG again after changing versions.
