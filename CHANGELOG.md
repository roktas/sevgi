# Changelog

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) and follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Unreleased

### Changed

- CI now exercises the exact Ruby 3.4.0 compatibility floor separately from the current development Ruby.

## 0.94.0 - 2026-07-10

### Changed

- Breaking: made geometry element collections immutable and element equality/hash exact; use `#eq?(precision:)` for
  approximate element comparison.
- Breaking: replaced `Derender.evaluate!` and `Derender.evaluate_file!` with explicit `evaluate_children` and
  `evaluate_file_children` children-only APIs.

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
