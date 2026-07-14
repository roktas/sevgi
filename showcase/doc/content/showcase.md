+++
title = "Showcase Examples"
weight = 20
[extra]
group = "More"
+++

These examples[^victor-book] are the executable `.sevgi` files from `showcase/srv`, not copies written for the site.
The test suite runs each file and compares its output. Open the Ruby panel for the script and the SVG panel for the
result. Most are small enough to read in one sitting, though a few keep enough detail to show how a real drawing comes
together.

<div class="showcase-flow">
{{ tabs(base="meter-face", dir="../showcase") }}
{{ tabs(base="grid-cells", dir="../showcase") }}
{{ tabs(base="gear-wheel",  dir="../showcase") }}
{{ tabs(base="checker-board", dir="../showcase") }}
{{ tabs(base="heart-mask",  dir="../showcase") }}
{{ tabs(base="snow-flake",  dir="../showcase") }}
{{ tabs(base="pacman-single", dir="../showcase") }}
{{ tabs(base="pacman-pokey",  dir="../showcase") }}
{{ tabs(base="ruler-hline",   dir="../showcase") }}
</div>

[^victor-book]: Some examples are adapted from the [Victor Book examples](https://github.com/DannyBen/victor-book/tree/master/src/examples).
