+++
title = "Functions"
weight = 15
[extra]
group = "Toolkit"
+++

`Sevgi::F` collects helpers shared by the Sevgi components. It includes numeric operations as well as string, file,
shell, and terminal helpers. Drawings most often use its math methods.

```ruby
Sevgi::F.with_precision(3) do
  Sevgi::F.cos(60)     # degree-based trigonometry
  Sevgi::F.approx(1.0 / 3)
end
```

Precision belongs to the current thread. Use `with_precision` for a block or pass `precision:` for one calculation.
The [API reference](https://www.rubydoc.info/gems/sevgi-function) lists the rest of the function module.
