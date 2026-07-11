# Changelog

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) and follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Unreleased

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
