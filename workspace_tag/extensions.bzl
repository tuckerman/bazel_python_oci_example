"""Module extension to expose a workspace tag."""

_TAG_FILE = ".workspace_tag"


def _workspace_tag_repo_impl(repo_ctx):
    path = repo_ctx.workspace_root.get_child(_TAG_FILE)
    if not path.exists:
        fail("No workspace tag found. Run `bazel run //workspace_tag:init -- --force` first.")

    tag = repo_ctx.read(str(path)).strip()
    if not tag:
        fail("Workspace tag file is empty. Regenerate it with `bazel run //workspace_tag:init -- --force`.")

    repo_ctx.file(
        "defs.bzl",
        content = "WORKSPACE_TAG = %r\n" % tag,
    )
    repo_ctx.file("BUILD.bazel", content = "exports_files(['defs.bzl'])\n")


workspace_tag_repository = repository_rule(implementation = _workspace_tag_repo_impl)


def _workspace_tag_ext_impl(mctx):
    workspace_tag_repository(name = "workspace_tag")


workspace_tag_ext = module_extension(implementation = _workspace_tag_ext_impl)
