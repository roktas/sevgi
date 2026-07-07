+++
title = "Showcase Examples"
weight = 3
+++

Sevgi examples are executable `.sevgi` scripts. Each example in this page is generated from the tested source files in
`showcase/srv`; the SVG panel shows the rendered output, and the Ruby panel shows the script that produced it.

## Programmatic Shapes

These examples are small enough to read end to end, but they already show the main workflow: keep drawing data in Ruby,
then emit SVG elements through the DSL.

{{ tabs(base="meter-face", dir="../showcase") }}
{{ tabs(base="grid-cells", dir="../showcase") }}

## Composition

Sevgi is most useful when the drawing is a composition of repeated parts, masks, symbols, or calculated positions.

{{ tabs(base="gear-wheel",  dir="../showcase") }}
{{ tabs(base="heart-mask",  dir="../showcase") }}
{{ tabs(base="snow-flake",  dir="../showcase") }}

## DSL Helpers

The core DSL can emit raw SVG elements directly, but helper methods are available for common drawing patterns.

{{ tabs(base="pacman-single", dir="../showcase") }}
{{ tabs(base="ruler-hline",   dir="../showcase") }}
