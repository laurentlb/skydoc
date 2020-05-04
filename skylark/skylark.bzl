# Copyright 2016 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Skylark rules"""

load("@bazel_skylib//:bzl_library.bzl", "StarlarkLibraryInfo")

_SKYLARK_FILETYPE = [".bzl"]

ZIP_PATH = "/usr/bin/zip"

def _skydoc(ctx):
    for f in ctx.files.skydoc:
        if not f.path.endswith(".py"):
            return f
    fail("no valid .py file")

def _skylark_doc_impl(ctx):
    """Implementation of the skylark_doc rule."""
    skylark_doc_zip = ctx.outputs.skylark_doc_zip
    direct = []
    transitive = []
    skydoc = _skydoc(ctx)
    for dep in ctx.attr.srcs:
        if StarlarkLibraryInfo in dep:
            direct.extend(dep[StarlarkLibraryInfo].srcs)
            transitive.append(dep[StarlarkLibraryInfo].transitive_srcs)
        else:
            direct.extend(dep.files.to_list())
    inputs = depset(order = "postorder", direct = direct, transitive = transitive + [
        dep[StarlarkLibraryInfo].transitive_srcs
        for dep in ctx.attr.deps
    ])
    sources = [source.path for source in direct]
    flags = [
        "--format=%s" % ctx.attr.format,
        "--output_file=%s" % ctx.outputs.skylark_doc_zip.path,
    ]
    if ctx.attr.strip_prefix:
        flags.append("--strip_prefix=%s" % ctx.attr.strip_prefix)
    if ctx.attr.overview:
        flags.append("--overview")
    if ctx.attr.overview_filename:
        flags.append("--overview_filename=%s" % ctx.attr.overview_filename)
    if ctx.attr.link_ext:
        flags.append("--link_ext=%s" % ctx.attr.link_ext)
    if ctx.attr.site_root:
        flags.append("--site_root=%s" % ctx.attr.site_root)
    ctx.actions.run(
        inputs = inputs,
        tools = [skydoc],
        executable = skydoc,
        arguments = flags + sources,
        outputs = [skylark_doc_zip],
        mnemonic = "Skydoc",
        use_default_shell_env = True,
        progress_message = ("Generating Skylark doc for %s (%d files)" %
                            (ctx.label.name, len(sources))),
    )

skylark_doc = rule(
    _skylark_doc_impl,
    attrs = {
        "srcs": attr.label_list(
            providers = [StarlarkLibraryInfo],
            allow_files = _SKYLARK_FILETYPE,
        ),
        "deps": attr.label_list(
            providers = [StarlarkLibraryInfo],
            allow_files = False,
        ),
        "format": attr.string(default = "markdown"),
        "strip_prefix": attr.string(),
        "overview": attr.bool(default = True),
        "overview_filename": attr.string(),
        "link_ext": attr.string(),
        "site_root": attr.string(),
        "skydoc": attr.label(
            default = Label("//skydoc"),
            cfg = "host",
            executable = True,
        ),
    },
    outputs = {
        "skylark_doc_zip": "%{name}-skydoc.zip",
    },
)

# buildozer: disable=no-effect
"""Generates Skylark rule documentation.

Documentation is generated in directories that follows the package structure
of the input `.bzl` files. For example, suppose the set of input files are
as follows:

* `foo/foo.bzl`
* `foo/bar/bar.bzl`

The archive generated by `skylark_doc` will contain the following generated
docs:

* `foo/foo.html`
* `foo/bar/bar.html`

Args:
  srcs: List of `.bzl` files that are processed to create this target.
  deps: List of other `skylark_library` targets that are required by the Skylark
    files listed in `srcs`.
  format: The type of output to generate. Possible values are `"markdown"` and
    `"html"`.
  strip_prefix: The directory prefix to strip from the generated output files.

    The directory prefix to strip must be common to all input files. Otherwise,
    skydoc will raise an error.
  overview: If set to `True`, then generate an overview page.
  overview_filename: The file name to use for the overview page. By default,
    the page is named `index.md` or `index.html` for Markdown and HTML output
    respectively.
  link_ext: The file extension used for links in the generated documentation.
    By default, skydoc uses `.html`.
  site_root: The site root to be prepended to all URLs in the generated
    documentation, such as links, style sheets, and images.

    This is useful if the generated documentation is served from a subdirectory
    on the web server. For example, if the skydoc site is to served from
    `https://host.com/rules`, then by setting
    `site_root = "https://host.com/rules"`, all links will be prefixed with
    the site root, for example, `https://host.com/rules/index.html`.

Outputs:
  skylark_doc_zip: A zip file containing the generated documentation.

Example:
  Suppose you have a project containing Skylark rules you want to document:

  ```
  [workspace]/
      WORKSPACE
      checkstyle/
          BUILD
          checkstyle.bzl
  ```

  To generate documentation for the rules and macros in `checkstyle.bzl`, add the
  following target to `rules/BUILD`:

  ```python
  load("@io_bazel_skydoc//skylark:skylark.bzl", "skylark_doc")

  skylark_doc(
      name = "checkstyle-docs",
      srcs = ["checkstyle.bzl"],
  )
  ```

  Running `bazel build //checkstyle:checkstyle-docs` will generate a zip file
  containing documentation for the public rules and macros in `checkstyle.bzl`.

  By default, Skydoc will generate documentation in Markdown. To generate
  a set of HTML pages that is ready to be served, set `format = "html"`.
"""
