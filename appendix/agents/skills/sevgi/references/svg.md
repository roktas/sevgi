# SVG Routing

Use this page to identify the SVG mechanism, then verify exact behavior in MDN or the SVG specification. Do not turn
this index into a cookbook of one-off drawing tips.

| Rendering concept | Start with |
| --- | --- |
| Coordinate system and responsive scaling | `viewBox`, viewport dimensions, `preserveAspectRatio` |
| Relative placement of an element tree | `transform`; use Sevgi's transform helpers when available |
| Reusable drawing definitions | `defs`, `symbol`, `use` |
| Repeated visual fill | `pattern` |
| Paint | presentation attributes or CSS, gradients, opacity |
| Visibility boundaries | `clipPath` for hard clipping; `mask` for luminance/alpha compositing |
| Line decoration | `marker`, stroke width, line cap, line join, dash array |
| Renderer effects | `filter` and filter primitives |
| Text relationships | text positioning and anchoring attributes; leave font metrics to the renderer |

Resolve questions in this order:

1. Identify the relationship the drawing needs, not a guessed numeric result.
2. Find the standard SVG element, attribute, or CSS behavior that owns it.
3. Check target-renderer support and inheritance rules when the feature is context-sensitive.
4. Express it through normal Sevgi element calls and attributes. Use `Element` only when a verified XML element name
   cannot dispatch safely as a Ruby call, such as a name that conflicts with an existing Ruby or Sevgi method. Never use
   it as a fallback for an unverified DSL word.
5. Compute geometry only when SVG does not provide the value needed by the program.

Authoritative references:

- [MDN SVG reference](https://developer.mozilla.org/en-US/docs/Web/SVG/Reference)
- [W3C SVG 2 specification](https://www.w3.org/TR/SVG2/)
- [Sevgi SVG Essentials](https://sevgi.roktas.dev/svg/)

Do not invent an SVG name from memory when validation matters. Check MDN and let Sevgi Standard validate known element
names, attributes, content, and nesting.
