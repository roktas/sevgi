# Changelog

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) and follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Unreleased

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
