# Bazel Python OCI Example

Example bazel module that creates a `container_app` wrapper rule.

This repo creates the workspace_tag extension which allows developers to tag their workspace (via the init script) and then subsequently use that tag for when working with containers. The goal is to have a "latest" tag per user in a shared oci repo.

## Init workspace tag (required first)

```sh
bazel run //workspace_tag:init
```

Be sure to add .workspace_tag to your .gitignore!

## Enable stamped tags

Workspace and timestamp tags are now generated via Bazel stamping. Run push/load
targets with the workspace status script so the tag and timestamp are available:

```sh
bazel run --stamp --workspace_status_command=./workspace_tag/status.py //demo:hello_world_push
```

The same command-line options apply to `//demo:hello_world_load` (or any target
created with the `container_app` macro).

## Python example

### Run the python binary locally

```sh
bazel run //demo:hello_world
```

### Run the oci image locally

```sh
bazel run //demo:hello_world_load
```

Get the image id from the above output

```sh
podman run --rm local-tag-here
```

### Push the oci image

```sh
bazel run //demo:hello_world_push
```

### Run the cli

The cli automatically inherits the deps of the app_target via the pydeps_proxy. You can verify this with the --path flag

```
bazel run //demo:hello_world_cli -- --path demo
```

This should print out the tag that would have been/was pushed
