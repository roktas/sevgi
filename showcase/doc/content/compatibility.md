+++
title = "Compatibility Boundary"
weight = 4
+++

Sevgi is designed to support script-style SVG generation through a compact Ruby DSL. The public boundary for users is
the documented DSL and the tested showcase workflow, not every internal helper or every downstream usage pattern.

## What Is Stable

The stable boundary for Sevgi users is the Sevgi DSL, the documented components, and the runnable showcase examples.
Those examples are the best starting point because they are executable and tested with the current source tree.

Prefer documented DSL words in scripts: `SVG`, SVG element names, and helper methods such as `TileX`. Regular Ruby code
belongs around the DSL when the drawing needs loops, data structures, calculations, or small helper objects.

## What Is Not A Contract

Implementation details are not public API. Avoid depending on private constants, registry internals, generated helper
classes, cache state, or undocumented method aliases.

If a script needs a behavior that is not covered by the docs or examples, treat that as a design question first. The
right next step may be documenting an existing public behavior, adding a tested helper, or changing the script to use a
more direct SVG construct.

## Version Choice

For reproducible documents, pin the Sevgi version used to generate them. For exploratory work, using the current source
tree is fine, but generated SVG should be reviewed when the dependency changes.
