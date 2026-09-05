+++
title = "Examples"
weight = 3
[extra]
group = "Start"
+++

These examples are the executable `.sevgi` files from `showcase/srv`, not copies written for the site. The test suite
runs each file and compares its output. Open the Ruby panel for the script. Open the SVG panel for the result. Most
examples are short, but several show how a complete drawing fits together. Some are adapted from the
[Victor Book examples](https://github.com/DannyBen/victor-book/tree/master/src/examples).

Start with Pokey for the basic element DSL, then use these examples to trace larger ideas:

| Example | What to inspect |
| --- | --- |
| Pacman | Plain SVG elements, nested groups, transforms, and repeated scene objects in a compact script |
| Checkers | Ruby data and callable modules separating board construction from piece placement |
| Ruler | Ruby ranges, nested layers, labels, and a final element transform in one physical-size drawing |
| Protractor | SVG rotation places angular marks from Ruler divisions without trigonometry in Ruby |
| Arc | Geometry calculates a finite elliptical arc, its endpoints, bounds, and length |
| Grid | Nested Ruby loops, derived coordinates, and data-driven color selection |
| Squared and Copperplate | One Grid contract reused for two guidesheets, with Copperplate adding row-bounded hatching |
| Logos | Repeated drawing parts assembled into several related marks |

<div class="showcase-flow">
{{<tabs base="pokey" dir="../showcase" title="Pokey" />}}
{{<tabs base="grid" dir="../showcase" title="Grid" />}}
{{<tabs base="stars" dir="../showcase" title="Stars" />}}
{{<tabs base="snowflake" dir="../showcase" title="Snowflake" />}}
{{<tabs base="clover" dir="../showcase" title="Clover" />}}
{{<tabs base="tulips" dir="../showcase" title="Tulips" />}}
{{<tabs base="pacman" dir="../showcase" title="Pacman" />}}
{{<tabs base="meter" dir="../showcase" title="Meter" />}}
{{<tabs base="heart" dir="../showcase" title="Heart" />}}
{{<tabs base="gear" dir="../showcase" title="Gear" />}}
{{<tabs base="logo" dir="../showcase" title="Logo" />}}
{{<tabs base="logos" dir="../showcase" title="Logos" />}}
{{<tabs base="checkers" dir="../showcase" title="Checkers" />}}
{{<tabs base="ruler" dir="../showcase" title="Ruler" />}}
{{<tabs base="protractor" dir="../showcase" title="Protractor" />}}
{{<tabs base="arc" dir="../showcase" title="Arc" />}}
{{<tabs base="squared" dir="../showcase" title="Squared" />}}
{{<tabs base="copperplate" dir="../showcase" title="Copperplate" />}}
</div>
