"""Initializes the workspace-wide container tag stored in `.workspace_tag`."""

from __future__ import annotations

import argparse
import os
import pathlib
import socket
import subprocess
import sys
import uuid


def _normalize_component(value: str) -> str:
    cleaned = []
    for ch in value.lower():
        if ch.isalnum() or ch in ["-", "_", "."]:
            cleaned.append(ch)
        else:
            cleaned.append("-")
    sanitized = "".join(cleaned).strip("-._")
    return sanitized or "workspace"


def _collect_user() -> str:
    user = os.environ.get("USER") or os.environ.get("USERNAME")
    if user:
        return _normalize_component(user)
    try:
        result = subprocess.run(
            ["/usr/bin/env", "id", "-un"],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )
        if result.returncode == 0:
            candidate = result.stdout.strip()
            if candidate:
                return _normalize_component(candidate)
    except OSError:
        pass
    return "user"


def _resolve_workspace() -> pathlib.Path:
    workspace = os.environ.get("BUILD_WORKSPACE_DIRECTORY")
    if not workspace:
        raise RuntimeError("BUILD_WORKSPACE_DIRECTORY is not set")
    return pathlib.Path(workspace)


def _default_tag() -> str:
    fqdn = socket.getfqdn().strip().lower()
    host = fqdn
    domain = ""
    if "." in fqdn:
        host, domain = fqdn.split(".", 1)
    host_part = _normalize_component(host) or "host"
    domain_part = _normalize_component(domain) if domain else ""
    user_part = _collect_user()
    host_combo = host_part if not domain_part else f"{host_part}.{domain_part}"
    return "-".join([user_part, host_combo, uuid.uuid4().hex[:12]])


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite an existing .workspace_tag instead of failing",
    )
    parser.add_argument(
        "--value",
        help="Explicit tag value to write; defaults to a hostname-based UUID",
    )

    args = parser.parse_args(argv[1:])

    try:
        workspace_root = _resolve_workspace()
    except RuntimeError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    tag_value = args.value or _default_tag()
    tag_path = workspace_root / ".workspace_tag"

    if tag_path.exists() and not args.force:
        print(
            f"error: {tag_path} already exists; rerun with --force to overwrite",
            file=sys.stderr,
        )
        return 1

    tag_path.write_text(tag_value + "\n", encoding="utf-8")
    print(f"wrote tag {tag_value} to {tag_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
