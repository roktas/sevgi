[![test status](https://github.com/roktas/sevgi/workflows/Test/badge.svg)](https://github.com/roktas/sevgi/actions?query=workflow%3ATest)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/ff0a9c3e65894040800b44867cd28198)](https://app.codacy.com/gh/roktas/sevgi/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)

# SEVGI

**SEVGI** is a toolkit for creating SVG content programmatically with Ruby as demonstrated below[^1]. You can use it to
create pixel-perfect graphics without using a vector graphics editor in certain scenarios. Thanks to a mixin based
design, you can easily add custom features and use a rich set of methods, especially for tiling, hatching and various
geometric operations.

### Roadmap

> [!WARNING]
> The project is currently in pre-alpha stage. So many things might not work and many things can change.

Alpha stage

- [ ] Stabilize API.
- [ ] Complete unit tests for all critical code paths.
- [ ] Populate examples while adding integration tests.
- [ ] Write entry-level user documentation.

Beta stage

- [ ] Complete user documentation.
- [ ] Start documenting API.

Final stage

- [ ] Complete Geometry library.

[^1]:
    Inspired by [Victor](https://github.com/DannyBen/victor), which might be a better choice for those seeking something
    simpler. Please note that a fair amount of the examples used for demonstration purposes come from this project
    (thanks to the author).
