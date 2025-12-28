# Docs Site

This is the Zola-based documentation site for Sevgi, published at sevgi.roktas.dev.

## Development workflow

Start the dev server from the docs directory:

```bash
cd srv && zola serve -p $((10000 + RANDOM))
```

### Verifying changes

**Text-only changes** (prose edits, content rewrites): Run pre-commit and provide the dev server link. Playwright
verification is not required.

**Visual changes** (CSS, layout, templates, responsive breakpoints): Use Playwright MCP to verify before returning.
Visual bugs often hide in CSS specificity, template inheritance, and responsive behavior.

Playwright workflow for visual changes:

1. Navigate to affected page(s)

2. Take a snapshot to verify rendered output

3. Iterate if the result doesn't match expectations

Common visual issues to check:

- Text positioning and visibility
- Spacing and alignment
- Regressions on nearby elements
- Responsive behavior (use `browser_resize`)

**Always include the dev server link** when returning after doc changes:

```
View changes: http://127.0.0.1:<port>
```

## Theme architecture

The docs use a standalone "warm workbench" theme. Key files:

| File                        | Purpose                                            |
| --------------------------- | -------------------------------------------------- |
| `templates/_var.html`       | CSS custom properties (colors, layout, typography) |
| `static/css/main.css`       | All styling, organized by section                  |
| `templates/base.html`       | Head overrides, iOS viewport polyfill              |
| `templates/index.html`      | Homepage hero and animations                       |
| `templates/page.html`       | Doc page TOC rendering                             |

### Layout system

The sticky header and TOC use **definitional CSS variables** so positions are always in sync:

```
--wt-header-height: 60px    (includes border via box-sizing: border-box)
--wt-main-padding-top: 40px

TOC sticks at: calc(header + padding) = 100px
Anchor scroll-margin: same calculation
```

When either variable changes (including via media queries), all dependent values update automatically. This prevents the
TOC from "jumping" when transitioning to sticky mode.

### Key technical decisions

1. **`box-sizing: border-box` on header** - Border is included in height, simplifying calculations
2. **`scrollbar-gutter: stable`** - Reserves scrollbar space to prevent layout shift on navigation
3. **IntersectionObserver intercept** - Ensures scroll-spy doesn't conflict with TOC styling
4. **Logo preload** - Prevents flash when navigating between pages
5. **WCAG AA colors** - `--wt-color-text-soft` is #78716a for 4.5:1 contrast
6. **iOS viewport polyfill** - Sets stable `--vh-full` variable for Firefox iOS/Chrome iOS (see `templates/base.html`
   for details on the jank issue and what we tried)

### Responsive breakpoints

Variables are overridden in media queries to maintain definitional correctness:

- **≤1024px**: `--wt-main-padding-top: 30px`
- **≤768px**: `--wt-header-height: 50px`, `--wt-main-padding-top: 20px`, TOC hidden

### Extending the theme

When adding new positioned elements:

- Use the layout variables rather than hardcoding pixel values
- Test anchor navigation to verify no visual jumps
- Check both with and without page scroll
