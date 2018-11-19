---
layout: default
title: Getting started
---

Stardoc is a documentation generator for [Bazel](https://bazel.build) build rules
written in [Starlark](https://bazel.build/docs/skylark/index.html).

Stardoc provides a Starlark rule (`stardoc`)
that can be used to build Markdown documentation for Starlark rules, providers,
and functions.
Starlark generates one documentation page per `stardoc` target.

If you are new to writing build rules for Bazel, please read the Bazel
documentation on [writing
extensions](https://www.bazel.build/docs/skylark/concepts.html)

<img src="/images/screenshot.png" class="responsive"
    alt="A screenshot of Stardoc generated documentation">

## Setup

To use Stardoc, add the following to your `WORKSPACE` file:

```python
git_repository(
    name = "bazel_skylib",
    remote = "https://github.com/bazelbuild/bazel-skylib.git",
    tag = "0.2.0",
)

git_repository(
    name = "io_bazel_skydoc",
    remote = "https://github.com/bazelbuild/skydoc.git",
    tag = "0.1.5",
)
```

Note that the `bazel_skylib` repository must also be loaded since Stardoc uses
this library.

If you would like to load the `stardoc` rule by default using Bazel's prelude, add
the following to the file `tools/build_rules/prelude_bazel` in your repository:

```python
load(
    "@io_bazel_skydoc//skylark:stardoc.bzl",
    "stardoc",
)
```

## Next Steps

Now you are ready to document your Starlark rules.

* Learn about the [docstring format][format] used to document Starlark rules.
* Learn about how you can use Stardoc's [build rules][generate] to generate your
  documentation in Markdown format.

[format]: writing_stardoc.html
[generate]: generating_stardoc.html
