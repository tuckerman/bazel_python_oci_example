load("@rules_pkg//pkg:pkg.bzl", "pkg_tar")
load("@rules_python//python:defs.bzl", "py_binary")
load("@rules_oci//oci:defs.bzl", "oci_image", "oci_load", "oci_push")
load("@image_tag//:defs.bzl", "DEFAULT_IMAGE_TAG")

def container_app(
        name,
        app_target,
        base,
        repository,
        entrypoint = None,
        local_repo = None,
        extra_tags = [],
        tag = None,
    ):

    # Defaults to the py_binary as the entrypoint.
    if not entrypoint:
        entrypoint = ["/" + name]

    # Defaults to the target name for local tagging
    if not local_repo:
        local_repo = name

    # Defaults to use a generated tag if none is provided.
    if tag == None:
        tag = DEFAULT_IMAGE_TAG

    local_tag = "local-" + tag
    repo_tags = [tag] + list(extra_tags)

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
        srcs = ["//containers:cli.py"],
        main = "cli.py",
        python_version = "PY3",
        args = ["--tag", tag],
    )
