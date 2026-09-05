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

Start with [Pokey](#pokey) for the basic element DSL.

<details class="example-index">
<summary>Explore examples</summary>

| Example | What to inspect |
| --- | --- |
| [Pokey](#pokey) | Basic SVG elements and a path |
| [Grid](#grid) | Nested Ruby loops, derived coordinates, and data-driven color selection |
| [Stars](#stars) | A symbol repeated in a tile grid |
| [Snowflake](#snowflake) | Repeated branches and rotation |
| [Clover](#clover) | Repeated shapes and transforms |
| [Tulips](#tulips) | Repeated flower shapes |
| [Pacman](#pacman) | Plain SVG elements, nested groups, transforms, and repeated scene objects in a compact script |
| [Meter](#meter) | Repeated LEDs with position-dependent opacity |
| [Heart](#heart) | A curved path used as a mask |
| [Gear](#gear) | Repeated teeth around a circle |
| [Logo](#logo) | A reusable path |
| [Logos](#logos) | Repeated drawing parts assembled into several related marks |
| [Checkers](#checkers) | Ruby data and callable modules separating board construction from piece placement |
| [Ruler](#ruler) | Ruby ranges, nested layers, labels, and a final element transform in one physical-size drawing |
| [Protractor](#protractor) | SVG rotation places angular marks from Ruler divisions without trigonometry in Ruby |
| [Arc](#arc) | Geometry calculates a finite elliptical arc, its endpoints, and bounds |
| [Squared](#squared) | A Grid defines a squared guidesheet |
| [Copperplate](#copperplate) | The same Grid contract adds row-bounded hatching |

</details>

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
