+++
title = "DSL Catalog"
weight = 11
[extra]
group = "Core"
+++

The DSL has two related vocabularies. Lowercase calls such as `rect`, `circle`, and `linearGradient` are SVG element
names. The full `sevgi` gem recognizes standard elements and checks their attributes, content, and nesting before
writing the document.

Sevgi's own drawing words usually begin with a capital letter, which keeps operations such as `Tile`, `Rotate`, and
`Include` visually distinct from SVG. A few deliberate lowercase words, including `css`, `layer`, and `base`, appear
here too. Ordinary Ruby methods and exhaustive signatures belong in the API reference.

## SVG elements {#svg-elements}

Use SVG element names directly and nest containers naturally:

```ruby
SVG :minimal do
  g id: "badge" do
    circle cx: 12, cy: 12, r: 10
    text "S", x: 12, y: 16, "text-anchor": "middle"
  end
end.Out
```

Use [`Element`](/dsl/#element) for foreign XML, qualified names, or a name that collides with Ruby. See
[SVG Essentials](@/svg.md) for the validation lifecycle and the
[MDN SVG element reference](https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Element) for the standard
element vocabulary.

## Browse by task {#browse-by-task}

Some words appear in more than one group. `Include`, for example, belongs to both composition and round trip. `Grid`
belongs to layout and script tools.

{{ dsl_index() }}

## Alphabetical index {#alphabetical-index}

[_](#letter-symbol) · [A](#letter-a) · [B](#letter-b) · [C](#letter-c) · [D](#letter-d) · [E](#letter-e) ·
[F](#letter-f) · [G](#letter-g) · [H](#letter-h) · [I](#letter-i) · [L](#letter-l) · [M](#letter-m) ·
[N](#letter-n) · [O](#letter-o) · [P](#letter-p) · [R](#letter-r) · [S](#letter-s) · [T](#letter-t) ·
[V](#letter-v) · [W](#letter-w)

### _ {#letter-symbol}

{{ dsl_letter(letter="_") }}

### A {#letter-a}

{{ dsl_letter(letter="A") }}

### B {#letter-b}

{{ dsl_letter(letter="B") }}

### C {#letter-c}

{{ dsl_letter(letter="C") }}

### D {#letter-d}

{{ dsl_letter(letter="D") }}

### E {#letter-e}

{{ dsl_letter(letter="E") }}

### F {#letter-f}

{{ dsl_letter(letter="F") }}

### G {#letter-g}

{{ dsl_letter(letter="G") }}

### H {#letter-h}

{{ dsl_letter(letter="H") }}

### I {#letter-i}

{{ dsl_letter(letter="I") }}

### L {#letter-l}

{{ dsl_letter(letter="L") }}

### M {#letter-m}

{{ dsl_letter(letter="M") }}

### N {#letter-n}

{{ dsl_letter(letter="N") }}

### O {#letter-o}

{{ dsl_letter(letter="O") }}

### P {#letter-p}

{{ dsl_letter(letter="P") }}

### R {#letter-r}

{{ dsl_letter(letter="R") }}

### S {#letter-s}

{{ dsl_letter(letter="S") }}

### T {#letter-t}

{{ dsl_letter(letter="T") }}

### V {#letter-v}

{{ dsl_letter(letter="V") }}

### W {#letter-w}

{{ dsl_letter(letter="W") }}
