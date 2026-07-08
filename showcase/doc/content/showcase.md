+++
title = "Showcase Examples"
weight = 3
+++

Sevgi examples are executable `.sevgi` scripts generated from the tested source files in `showcase/srv`; the SVG panel
shows the rendered output, the Ruby panel shows the script that produced it, and the examples are small enough to read
end to end while still showing the main workflow: keep drawing data in Ruby, compose the drawing with helpers when
useful, then emit SVG elements through the DSL.

<div class="showcase-flow">
{{ tabs(base="meter-face", dir="../showcase") }}
{{ tabs(base="grid-cells", dir="../showcase") }}
{{ tabs(base="gear-wheel",  dir="../showcase") }}
{{ tabs(base="heart-mask",  dir="../showcase") }}
{{ tabs(base="snow-flake",  dir="../showcase") }}
{{ tabs(base="pacman-single", dir="../showcase") }}
{{ tabs(base="ruler-hline",   dir="../showcase") }}
</div>
