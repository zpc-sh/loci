#!/usr/bin/env python3
"""
emit_build_matrix.py — reads docs/BUILD_MATRIX.json, emits markdown tables,
and patches the README.md between sentinel comments.

Usage:
    python3 docs/emit_build_matrix.py              # patch README in-place
    python3 docs/emit_build_matrix.py --stdout     # print to stdout only
    python3 docs/emit_build_matrix.py --check      # exit 1 if README needs update
"""

import json
import sys
import re
from pathlib import Path

ROOT = Path(__file__).parent.parent
MATRIX_FILE = ROOT / "docs" / "BUILD_MATRIX.json"
README_FILE = ROOT / "README.md"

BEGIN_SENTINEL = "<!-- BUILD_MATRIX_BEGIN -->"
END_SENTINEL   = "<!-- BUILD_MATRIX_END -->"


def load_matrix() -> dict:
    return json.loads(MATRIX_FILE.read_text())


def render(m: dict) -> str:
    lines = []
    lines.append(f"{BEGIN_SENTINEL}\n")

    # ── Cognition work-cycle ──────────────────────────────────────────────────
    lines.append("## Cognition work-cycle\n")
    lines.append(
        "| Symbol | Cognition | Role | Package | Status |\n"
        "|--------|-----------|------|---------|--------|\n"
    )
    for c in m["cognitions"]:
        pkg = f"`{c['package']}`"
        badge = "✅ active" if c["status"] == "active" else "🗺️ planned"
        lines.append(
            f"| {c['symbol']} | **{c['label']}** | {c['role']} | {pkg} | {badge} |\n"
        )
    lines.append("\n")

    # ── MoonBit build targets ─────────────────────────────────────────────────
    lines.append("## MoonBit build targets\n")
    lines.append(
        "| Target | Preferred | Runtimes | Status |\n"
        "|--------|:---------:|----------|--------|\n"
    )
    for t in m["moon_targets"]:
        pref   = "⭐" if t["preferred"] else ""
        rt     = ", ".join(t["runtime"])
        badge  = "✅" if t["status"] == "active" else "🧪 experimental"
        lines.append(f"| `{t['id']}` | {pref} | {rt} | {badge} |\n")
    lines.append("\n")

    # ── Release platforms ─────────────────────────────────────────────────────
    lines.append("## Release platforms\n")
    lines.append(
        "| Platform | Runner | Artifact |\n"
        "|----------|--------|----------|\n"
    )
    for p in m["release_platforms"]:
        lines.append(
            f"| {p['label']} | `{p['runner']}` | `{p['artifact']}` |\n"
        )
    lines.append("\n")

    # ── Release artifacts ─────────────────────────────────────────────────────
    lines.append("## Release artifacts\n")
    lines.append(
        "| File | Description | Built by |\n"
        "|------|-------------|----------|\n"
    )
    for a in m["release_artifacts"]:
        lines.append(
            f"| `{a['filename']}` | {a['description']} | `{a['built_by']}` |\n"
        )
    lines.append("\n")

    # ── Future ────────────────────────────────────────────────────────────────
    fut = m.get("future", {}).get("cognition_compilation", {})
    if fut:
        lines.append("## Roadmap\n")
        lines.append(f"> **Cognition compilation** ({fut['status']}): {fut['description']}  \n")
        lines.append(f"> {fut['note']}\n\n")

    lines.append(f"{END_SENTINEL}")
    return "".join(lines)


def patch_readme(rendered: str) -> bool:
    """Patch README.md in-place. Returns True if content changed."""
    text = README_FILE.read_text(encoding="utf-8")

    pattern = re.compile(
        re.escape(BEGIN_SENTINEL) + r".*?" + re.escape(END_SENTINEL),
        re.DOTALL,
    )

    if pattern.search(text):
        new_text = pattern.sub(rendered, text)
    else:
        # No sentinels yet — append section before the last H2 or at end
        new_text = text.rstrip() + "\n\n" + rendered + "\n"

    if new_text == text:
        return False

    README_FILE.write_text(new_text, encoding="utf-8")
    return True


def main() -> None:
    args = set(sys.argv[1:])

    m = load_matrix()
    rendered = render(m)

    if "--stdout" in args:
        print(rendered)
        return

    if "--check" in args:
        text = README_FILE.read_text(encoding="utf-8")
        pattern = re.compile(
            re.escape(BEGIN_SENTINEL) + r".*?" + re.escape(END_SENTINEL),
            re.DOTALL,
        )
        current = pattern.search(text)
        if current and current.group(0) == rendered:
            print("✓ README build matrix is up to date")
            sys.exit(0)
        else:
            print("✗ README build matrix is stale — run `just build-matrix`")
            sys.exit(1)

    changed = patch_readme(rendered)
    if changed:
        print(f"✓ README.md patched with build matrix")
    else:
        print("✓ README.md already up to date")


if __name__ == "__main__":
    main()
