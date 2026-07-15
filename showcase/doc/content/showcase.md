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
{{ tabs(base="pokey", dir="../showcase", title="Pokey") }}
{{ tabs(base="grid", dir="../showcase", title="Grid") }}
{{ tabs(base="stars", dir="../showcase", title="Stars") }}
{{ tabs(base="snowflake", dir="../showcase", title="Snowflake") }}
{{ tabs(base="clover", dir="../showcase", title="Clover") }}
{{ tabs(base="tulips", dir="../showcase", title="Tulips") }}
{{ tabs(base="pacman", dir="../showcase", title="Pacman") }}
{{ tabs(base="meter", dir="../showcase", title="Meter") }}
{{ tabs(base="heart", dir="../showcase", title="Heart") }}
{{ tabs(base="gear", dir="../showcase", title="Gear") }}
{{ tabs(base="logo", dir="../showcase", title="Logo") }}
{{ tabs(base="logos", dir="../showcase", title="Logos") }}
{{ tabs(base="checkers", dir="../showcase", title="Checkers") }}
{{ tabs(base="ruler", dir="../showcase", title="Ruler") }}
{{ tabs(base="squared", dir="../showcase", title="Squared") }}
{{ tabs(base="copperplate", dir="../showcase", title="Copperplate") }}
</div>

[^victor-book]: Some examples are adapted from the [Victor Book examples](https://github.com/DannyBen/victor-book/tree/master/src/examples).
