"""Convenience macro for building, loading, and pushing container images."""

load("@rules_pkg//pkg:pkg.bzl", "pkg_tar")
load("@rules_oci//oci:defs.bzl", "oci_image", "oci_load", "oci_push")
load("@workspace_tag//:defs.bzl", "WORKSPACE_TAG")
load("//container_app:pydeps_proxy.bzl", "pydeps_proxy")
load("@rules_python//python:defs.bzl", "py_binary")


def _dedupe(items):
    seen = {}
    result = []
    for item in items:
        if item not in seen:
            seen[item] = True
            result.append(item)
    return result


def _is_local_python_rule(label):
    if type(label) != "string" or not label.startswith(":"):
        return False
    name = label[1:]
    rule = native.existing_rules().get(name)
    if not rule:
        return False
    kind = rule.get("rule") or rule.get("kind")
    if not kind:
        return False
    return kind in ("py_binary", "py_library", "py_test")


def container_app(
        name,
        app_target,
        base,
        repository,
        entrypoint = None,
        local_repo = None,
        extra_tags = None,
        add_latest_tag = False,
        tag = None,
    ):
    """Create targets to build, load, and push a container image for a Bazel target."""

    if not entrypoint:
        entrypoint = ["/" + name]

    if not local_repo:
        local_repo = name

    workspace_tag = WORKSPACE_TAG if tag == None else tag

    local_tag = "local-" + workspace_tag

    repo_tags = [workspace_tag, "container-app-%s" % workspace_tag]
    if extra_tags:
        repo_tags.extend(extra_tags)
    if add_latest_tag:
        repo_tags.append("latest")

    repo_tags = _dedupe(repo_tags)

    cli_deps = []
    if _is_local_python_rule(app_target):
        proxy_name = name + "_cli_deps_proxy"
        pydeps_proxy(
            name = proxy_name,
            src = app_target,
        )
        cli_deps.append(":" + proxy_name)

    pkg_tar(
        name = name + "_pkg",
        srcs = [app_target],
        include_runfiles = True,
        strip_prefix = "./",
    )

    oci_image(
        name = name + "_image",
        base = base,
        tars = [":" + name + "_pkg"],
        entrypoint = entrypoint,
    )

    oci_load(
        name = name + "_load",
        image = ":" + name + "_image",
        repo_tags = ["%s:%s" % (local_repo, local_tag)],
    )

    oci_push(
        name = name + "_push",
        image = ":" + name + "_image",
        repository = repository,
        tags = repo_tags,
    )

    py_binary(
        name = name + "_cli",
        srcs = ["//container_app:cli.py"],
        main = "cli.py",
        python_version = "PY3",
        deps = cli_deps,
        args = ["--tag", workspace_tag],
    )
