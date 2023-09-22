---
---

Example: Diagonal.new(slope: 4.0 / 3.0, intercept: 0.0)

This line forms a 3-4-5 triangular as illustrated below:

```
 o----3----+------- x
 | .       |
 |  .      |
 |   5     4
 |     .   |
 |      .  |
 |       . |
 +---------+
 |           .
 |             .
 |      angle = clockwise from x-axis = +53.13°, slope = (4 / 3)
 |
 y
```

Example: Diagonal.new(slope: -4.0 / 3.0, intercept: 4.0)

This line also forms a 3-4-5 triangular (symmetrically with the previous one):

```

        angle = counter clockwise from x-axis = -53.13°, slope = -(4 / 3)
              .
            .
 o---------+--------- x
 |       . |
 |      .  |
 |     5   |
 |   .     4
 |  .      |
 |.        |
 +----3----+
 |
 |
 |
 y
```


Distance is the length between lines in the direction perpendicular to the lines.

```
|
|                                                            .
|                                                          .
|                                                       .   (90° - angle)
o------+-------------------------+-------------------+------------------------ x
|        . angle                   .              .
|          .                         .         .
|            .                         .    .
|              .                         +
|                .                    .     .
|                  .            distance      .
|                    .         .                .
|                      .    .                     .
|                        +                          .
|                    .    .                           .
|                 .   90°   .                           .
|              .              .                           .
|           .                   .                           .
|      perpendicular            line                       line.shift(distance)
|
y
```

Example: Horizontal.new(4.0)

```
 o----------------- x
 |
 |
 4
 |
 |
 +..................
 |
 |
 y
```

Example: Vertical.new(3.0)

```
 o----3----+------- x
 |         .
 |         .
 |         .
 |         .
 |         .
 |         .
 |         .
 y
```
