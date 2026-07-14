+++
title = "Functions"
weight = 15
[extra]
group = "Toolkit"
+++

`Sevgi::F` is the shared function namespace used across the toolkit. It covers precise numeric helpers, strings, files,
shell execution, and terminal color. Most drawings only meet its math helpers directly.

```ruby
Sevgi::F.with_precision(3) do
  Sevgi::F.cos(60)     # degree-based trigonometry
  Sevgi::F.approx(1.0 / 3)
end
```

Precision is thread-local and scoped overrides are preferred. A per-call `precision:` is useful for one calculation.
Use the [API reference](https://www.rubydoc.info/gems/sevgi-function) for the full function inventory; this guide keeps
the focus on drawing workflows.
