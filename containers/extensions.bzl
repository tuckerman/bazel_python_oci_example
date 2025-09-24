"""Module extensions for container image tagging."""

def _image_tag_repo_impl(repo_ctx):
    ts, sha = "00000000-000000", "nogit"
    r = repo_ctx.execute(["/usr/bin/env", "date", "-u", "+%Y%m%d-%H%M%S"], quiet = True)
    if r.return_code == 0:
        ts = r.stdout.strip()
    r = repo_ctx.execute(["/usr/bin/env", "git", "rev-parse", "--short=12", "HEAD"], quiet = True)
    if r.return_code == 0:
        sha = r.stdout.strip()
    repo_ctx.file("defs.bzl", content = "DEFAULT_IMAGE_TAG = %r\n" % (ts + "-" + sha))
    repo_ctx.file("BUILD.bazel", content = "exports_files(['defs.bzl'])\n")


image_tag_repository = repository_rule(implementation = _image_tag_repo_impl)


def _image_tag_ext_impl(mctx):
    image_tag_repository(name = "image_tag")


image_tag_ext = module_extension(implementation = _image_tag_ext_impl)
