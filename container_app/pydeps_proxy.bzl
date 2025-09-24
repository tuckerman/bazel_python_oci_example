"""Helpers for proxying Python providers."""

load("@rules_python//python:py_info.bzl", "PyInfo")


def _pydeps_proxy_impl(ctx):
    source_info = ctx.attr.src[PyInfo]
    return [
        PyInfo(
            transitive_sources = source_info.transitive_sources,
            imports = source_info.imports,
            uses_shared_libraries = source_info.uses_shared_libraries,
            has_py2_only_sources = source_info.has_py2_only_sources,
            has_py3_only_sources = source_info.has_py3_only_sources,
        ),
        DefaultInfo(files = source_info.transitive_sources),
    ]


pydeps_proxy = rule(
    implementation = _pydeps_proxy_impl,
    attrs = {
        "src": attr.label(providers = [PyInfo]),
    },
    doc = "Forwards PyInfo from another Python target so it can be used in deps.",
)
