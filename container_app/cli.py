import argparse
import importlib
import os
import pkgutil


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--tag", required=True)
    parser.add_argument(
        "--path",
        action="append",
        help="Package prefix to inspect for modules (repeatable)",
    )
    args = parser.parse_args()
    print(f"tag: {args.tag}")

    prefixes = args.path or []
    discovered: dict[str, list[str] | None] = {}
    for prefix in prefixes:
        try:
            package = importlib.import_module(prefix)
        except ImportError:
            discovered[prefix] = None
            continue

        modules = []
        if hasattr(package, "__path__"):
            modules = sorted(
                name
                for _, name, _ in pkgutil.walk_packages(
                    package.__path__, prefix=f"{prefix}."
                )
            )
        else:
            module_file = getattr(package, "__file__", None)
            if module_file:
                directory = os.path.dirname(module_file)
                modules = sorted(
                    f"{prefix}.{entry.name[:-3]}"
                    for entry in os.scandir(directory)
                    if entry.is_file()
                    and entry.name.endswith(".py")
                    and entry.name != "__init__.py"
                )
        discovered[prefix] = modules

    for prefix in prefixes:
        modules = discovered.get(prefix)
        if modules is None:
            print(f"no package named {prefix}")
        elif not modules:
            print(f"no submodules discovered under {prefix}")
        else:
            print(f"discovered modules under {prefix}:")
            for module in modules:
                print(f"  - {module}")
