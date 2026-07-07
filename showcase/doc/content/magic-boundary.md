+++
title = "Magic Boundary"
weight = 4
+++

Magic is a downstream Sevgi consumer and an important compatibility signal during Sevgi development. It is not the
primary public interface for learning Sevgi, and this documentation does not treat Magic-specific conventions as Sevgi
API.

## What Is Stable

The stable boundary for Sevgi users is the Sevgi DSL and the documented components. The showcase examples are the best
starting point because they are executable and tested with the current source tree.

For Magic users, the default Magic workflow should keep using the Sevgi release selected by Magic. That keeps Magic
documents reproducible.

## What Is Development-Only

Testing Magic against a local Sevgi checkout is useful while changing Sevgi, but it is a development check rather than
an end-user workflow. Use it when you specifically need to validate Magic-style DSL usage against Sevgi HEAD:

```bash
(
	cd ../magic
	MAGIC_SEVGI=local bundle exec rake test
)
```

If that check fails, first determine whether the failure is a Sevgi regression, an intentional Sevgi API change, or a
Magic-side dependency on behavior that was never part of Sevgi's public contract.
