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
{{ tabs(base="pacman-pokey", dir="../showcase", title="Pokey") }}
{{ tabs(base="grid-cells", dir="../showcase", title="Grid") }}
{{ tabs(base="snow-flake", dir="../showcase", title="Snowflake") }}
{{ tabs(base="pacman-single", dir="../showcase", title="Pacman") }}
{{ tabs(base="meter-face", dir="../showcase", title="Meter") }}
{{ tabs(base="heart-mask", dir="../showcase", title="Heart") }}
{{ tabs(base="gear-wheel", dir="../showcase", title="Gear") }}
{{ tabs(base="scur-logo", dir="../showcase", title="Logo") }}
{{ tabs(base="scur-tile", dir="../showcase", title="Tile") }}
{{ tabs(base="checker-board", dir="../showcase", title="Checkers") }}
{{ tabs(base="ruler-hline", dir="../showcase", title="Ruler") }}
{{ tabs(base="guide-square", dir="../showcase", title="Squared") }}
{{ tabs(base="guide-copperlate", dir="../showcase", title="Copperplate") }}
</div>

[^victor-book]: Some examples are adapted from the [Victor Book examples](https://github.com/DannyBen/victor-book/tree/master/src/examples).
