# Changelog

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) and follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Unreleased

### Added

- Added exact, subtree-wide attribute omission to Derender content/file conversion, evaluation, and inclusion APIs;
  `igves --omit` exposes the same behavior from the command line.
- Added `Sevgi.SVG` as the explicit namespaced form of the top-level SVG document entrypoint.
- Added the opt-in recursive `SVG::Modules` contract for callable drawing namespaces.
- Added callable drawing-module `base` blocks, document and paper registry introspection, Canvas structural equality,
  renderer options on `RenderChildren`, axis translation helpers, and a CC BY RDF helper.
- Formalized non-rendering `-` metadata and `+` attribute updates as `Attributes::META_PREFIX` and
  `Attributes::UPDATE_SUFFIX`; repeated Array updates now concatenate into a stable flat value.

### Changed

- Made degree-based sine and cosine exact at integer quarter turns, eliminating cardinal Geometry residue.
- Documented complete file-system failure families for file comparison, output, touch, and upward location helpers.
- Formalized generated Tile ids, positional CSS classes, template placement, and per-use callback signatures.
- Formalized String and Symbol ids across Derender selection APIs and documented file-read failures consistently.
- Breaking: made top-level `Decompile`, `Derender`, `Evaluate`, and `EvaluateChildren` consume inline SVG/XML;
  file inputs now use the corresponding `File`-suffixed entrypoints.
- Breaking: replaced callable drawing module `call` block registration with argument-independent `base` blocks;
  inherited bases run parent-first, and modules with one drawing method conventionally name it `call`.
- Breaking: made bracket and call notation the canonical Geometry constructors. Among Data value types, bracket notation
  is public only for Point, Segment, LengthAngle, Margin, and Paper; use `.new` for Location and result carriers, and
  `Stay` for traversal stop tokens.
- Breaking: aligned Point and Segment comparison with Ruby `Comparable`; malformed or unrelated comparison operands now
  return nil from `<=>`.
- Breaking: executor entrypoints now return immutable `Executor::Result` values and expose only `execute` and
  `execute_file`; inspect `result.error`, `result.stack`, and `result.value` instead of executor scopes or lifecycle state.
- Breaking: wrapper attributes and callable arguments use distinct channels, `With` rejects parentless receivers, and
  unsupported direct constructors are private; use the documented factories for Content, concrete Geometry lined
  elements, and Grid query values.
- Breaking: Canvas uses `.new` for explicit fields, `.from_paper(paper, **overrides)` for paper conversion, and
  `.call`/`Graphics.canvas` for dispatch; the misleading keyword-only `.from_paper(width:, height:)` form was removed.
- Breaking: `Save`, `Write`, `PNG`, `PDF`, and Sundries native export normalize successful destinations to expanded
  String paths and create missing parent directories; change-aware SVG writes still return nil when unchanged.
- Breaking: renamed `Derender.evaluate_file_children` to `evaluate_children_file`; decompiled nodes now own immutable
  public state while parser, strategy, and construction plumbing remain private.
- Expanded runtime/YARD parity checks and exact contracts for inherited, extended, generated, and dynamic API surfaces,
  forwarded options, error channels, path ownership, whitespace, namespaces, nil behavior, and return values.

### Fixed

- Rejected directories from default file discovery while preserving custom locator matchers.
- Kept `Ancestral` context in non-rendering `-context` metadata instead of leaking it into SVG attributes.
- Preserved source Canvas units and names when deriving fitted Grid canvases.
- Prevented stale documentation assets from mixing old layouts with new HTML, and moved sidebar navigation into the
  tablet menu at 1024px and below.
- Normalized numeric slots owned by path, shape, transform, tile, and Inkscape page helpers to finite SVG number spelling;
  arbitrary user-supplied attributes remain untouched.
- Made named callable wrapper and symbol ids stable while omitting defaults for anonymous modules, and indexed every
  rendered id value, including false and numeric values, through its serialized string.
- Preserved signed Geometry constraint directions, rejected invalid sweep/export channels through Sevgi error families,
  and validated raw output paths before expansion or rendering.
- Made callable module configuration copy-owned and freeze-aware, document subclasses inherit their nearest profile, and
  false executor boot receivers remain explicit rather than defaulting to an internal scope.
- Made element trees, attributes, identifiers, locator results, document profiles, Derender nodes, shell results, and
  executor results retain owned immutable snapshots where their public contracts promise value semantics.
- Corrected Shell combined-output separators, nil export density errors, document render-option routing, executor source
  snapshots, selected-node namespace/whitespace documentation, and Standard character-data validation.

### Removed

- Removed public access to pluralization tables and the internal SVG save extension; pluralization rules are now deeply
  immutable.
- Removed public documentation and constant access for command-line implementation modules; the `sevgi` and `igves`
  executables remain unchanged.
- Removed eager loading and public documentation of private Showcase build/test support; explicit support entrypoints
  now keep the harness under the Showcase namespace.
- Removed public access to document profile name normalizers; registry operations retain them as private plumbing.
- Removed the redundant `Margin.margin` constructor; use canonical bracket notation.
- Removed public executor orchestration, obsolete callable-module hooks, the old public attribute syntax constants, and
  direct construction of abstract or internally wired Content, Element, and Grid query types.
- Removed accidental public access to abstract Lined factories, internal element-name/export maps, result/location
  bracket constructors, and direct Stop construction.

## 0.95.0 - 2026-07-11

### Security

- Validated XML-bound names, metadata, content, attributes, comments, preambles, and renderer inputs before serialization;
  mutable content and attribute inputs can no longer invalidate an earlier check.
- Emitted collision-safe Derender source and preserved qualified or foreign nodes without dispatching them through
  same-named Ruby or DSL methods.
- Verified physical gem payloads and checksums, then published immutable archives in dependency order from one manifest
  through pinned, least-privilege workflows.

### Added

- Added opt-in real-browser Showcase coverage for tab navigation and mobile SVG sizing, with failure-safe server and
  browser lifecycle tests.
- Added comprehensive public YARD contract checks plus focused release-preflight and root Rakefile coverage.

### Changed

- CI now exercises the exact Ruby 3.4.0 compatibility floor separately from the current development Ruby.
- Standard no longer caches missing SVG specifications, preserving later registry updates.
- Document and Paper profile registration is process-global and thread-atomic; identical non-bang definitions return the
  canonical registration while conflicting definitions fail without replacement.
- Content, document metadata, and attribute stores capture caller-independent snapshots and stringify custom mutable
  leaves once at their public mutation boundaries.
- Release verification validates actual archive contents, records their order and checksums in a manifest, and keeps the
  Ruby floor compatible with the checked-in bundle.

### Fixed

- Preserved mixed inline text, namespace-qualified and foreign nodes, whitespace, nested SVG elements, raw evaluation
  parents, and Ruby-name collisions during Derender conversion.
- Rejected cyclic or invalid graphics payloads, unsafe XML renderer inputs, non-finite canvas and geometry values, and
  malformed Standard, ruler, tile, grid, and export arguments before partial mutation or rendering.
- Kept open paths from receiving synthetic interiors and made per-call intersection precision independent of ambient
  thread precision.
- Made multi-element append/prepend ordered and atomic, document and paper registration coherent under contention, and
  copied graphics trees independent of their sources.
- Corrected PDF stamping across nested graphics-state restoration and duplicate stream rewrites.
- Made SIGINT forwarding trap-safe, balanced executor signal guards for empty scripts, and rejected recursive script-load
  cycles without losing the original executor context.
- Packaged canonical README, LICENSE, and CHANGELOG files in every component gem, made manifests and release verification
  independent of the working directory, validated physical package members, and preserved dependency order through the
  production publishing path.
- Made Showcase shell and browser cleanup failure-safe and kept generated examples stable across browser layouts.

### Removed

- Removed the stale internal `Undefined::Self` sentinel constant and obsolete root release-script plumbing.

## 0.94.0 - 2026-07-10

### Security

- XML content is validated before rendering, preventing control characters and unsafe markup from reaching generated
  documents.
- Derender evaluation treats XML as data rather than executable Ruby.

### Changed

- Breaking: made geometry element collections immutable and element equality/hash exact; use `#eq?(precision:)` for
  approximate element comparison.
- Breaking: replaced `Derender.evaluate!` and `Derender.evaluate_file!` with explicit `evaluate_children` and
  `evaluate_file_children` children-only APIs.
- Native PDF/PNG export dependencies are optional at runtime; users of those exporters must install Cairo/RSVG and the
  relevant PDF libraries explicitly.
- Executor, Showcase, and shell execution isolate process-global state and preserve nested load failures with their
  source context.
- Generated documentation and complete package archives are validated by release checks.

### Fixed

- Preserved parsed XML semantics and nested inline text during Derender conversion.
- Rejected cyclic duplicate/adoption operations and invalid graphics, geometry, Standard, ruler, tile, and export inputs
  before partial mutation or rendering.
- Reported PDF stamp replacements accurately.
- Hardened Showcase navigation, SVG preview scaling, rendered artifacts, and documentation layouts.

## 0.93.1 - 2026-07-08

### Changed

- Added the checker board example to the documentation showcase flow.
- Consolidated Victor Book attribution for adapted showcase examples into a single documentation note.

### Fixed

- Fixed documentation site deployment to build with Zola 0.22.1 so showcase code syntax highlighting is rendered in
  production.

## 0.93.0 - 2026-07-08

### Added

- Added scoped numeric precision control with thread-local defaults and `F.with_precision`.
- Added opt-in SimpleCov coverage reporting with generated output under `.cache/ruby/coverage`.
- Added YARD API documentation setup and initial public API documentation across the main components.
- Added initial user documentation pages and expanded showcase examples.

### Changed

- Breaking: cleaned up public API names and DSL ergonomics across geometry, graphics, derender, and sundries.
- Reworked graphics document and paper profile registration semantics around explicit DSL words.
- Stabilized executor load-stack handling and CLI error reporting for script-mode DSL failures.
- Moved generated Ruby tooling output under `.cache/ruby`.
- Separated GitHub Release verification from manual RubyGems publishing.

### Fixed

- Hardened graphics DSL dispatch, namespace isolation, document rendering, paper sizes, and validation handoff.
- Fixed derender escaping, executable text DSL output, evaluation, and load edge cases.
- Stabilized SVG standard validation, namespace handling, color data, and error contracts.
- Aligned geometry line shifting with equation offsets and tightened primitive edge cases.
- Stabilized sundries grid, ruler, tile, and native export edge cases.
- Fixed showcase rendering, SVG tab display, syntax highlighting, layout, and stale artifact handling.

### Removed

- Removed dead graphics canvas conforming API.
- Removed unsupported bang derender/decompile wrappers.

## 0.73.2 - 2026-07-04

### Fixed

- Removed parent-directory license paths from gem packages so published gems install cleanly.

## 0.73.1 - 2026-07-04

### Fixed

- Corrected the SVG standard `seashell` color value.
- Deferred `sevgi-sundries` export loading in graphics so optional native export dependencies are only loaded when
  `PDF` or `PNG` export is used.
- Removed a shadowed block parameter in graphics dispatch.
- Fixed component lint task execution from the repository root.

### Changed

- Updated the development Ruby version to 4.0.5 and refreshed the bundle.
- Adopted rubyfmt-driven formatting and updated RuboCop configuration.

## 0.73.0 - 2026-05-01

Initial release.
