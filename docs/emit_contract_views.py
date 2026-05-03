#!/usr/bin/env python3
"""
emit_contract_views.py

Generate cohesive contract views from canonical sources:
- wit/capsule/capsule.wit
- loci_fsm/personality.mbt

Outputs:
- docs/contracts/capsule_contract.json
- docs/contracts/fst_personalities.json
- docs/contracts/COHESIVE_CONTRACT_INDEX.md
- docs/contracts/CONTRACT_PRESENTATION.md
- docs/contracts/isomorphic_cards.html
- docs/contracts/badges/*.svg
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parent.parent
CAPSULE_WIT = ROOT / "wit" / "capsule" / "capsule.wit"
FST_PERSONALITY = ROOT / "loci_fsm" / "personality.mbt"
OUT_DIR = ROOT / "docs" / "contracts"
BADGE_DIR = OUT_DIR / "badges"


def read_text(p: Path) -> str:
    return p.read_text(encoding="utf-8")


def parse_capsule_wit(text: str) -> dict:
    pkg = re.search(r"package\s+([\w:]+)@([0-9.]+);", text)
    package_name = pkg.group(1) if pkg else "unknown"
    version = pkg.group(2) if pkg else "unknown"

    types_block = re.search(r"interface\s+types\s*\{(.*?)\n\}\n\n\ninterface\s+host", text, re.S)
    types_text = types_block.group(1) if types_block else ""

    capsule_block = re.search(r"interface\s+capsule\s*\{(.*?)\n\}\n\n\nworld", text, re.S)
    capsule_text = capsule_block.group(1) if capsule_block else ""

    type_records = re.findall(r"\brecord\s+([a-z0-9\-]+)\s*\{", types_text)
    type_enums = re.findall(r"\benum\s+([a-z0-9\-]+)\s*\{", types_text)
    type_variants = re.findall(r"\bvariant\s+([a-z0-9\-]+)\s*\{", types_text)

    fst_surfaces_block = re.search(r"enum\s+fst-surface\s*\{(.*?)\}", types_text, re.S)
    fst_surfaces = []
    if fst_surfaces_block:
        fst_surfaces = [x.strip().rstrip(",") for x in fst_surfaces_block.group(1).splitlines() if x.strip()]

    capsule_fns = re.findall(r"^\s*([a-z0-9\-]+):\s*func\(", capsule_text, re.M)

    fst_ops = [
        fn for fn in capsule_fns
        if fn.startswith("transducer-") or fn.startswith("swarm-") or fn.startswith("fst-")
    ]

    assurance_fns = [fn for fn in capsule_fns if fn.startswith("fst-")]

    return {
        "package": package_name,
        "version": version,
        "generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "source": str(CAPSULE_WIT.relative_to(ROOT)),
        "types": {
            "records": sorted(type_records),
            "enums": sorted(type_enums),
            "variants": sorted(type_variants),
            "counts": {
                "records": len(type_records),
                "enums": len(type_enums),
                "variants": len(type_variants),
            },
        },
        "capsule_functions": capsule_fns,
        "fst": {
            "operations": fst_ops,
            "assurance_functions": assurance_fns,
            "surfaces": fst_surfaces,
            "network_direct_allowed": False,
            "network_policy_note": "No network surface is declared; deny-network is policy-first.",
        },
    }


def parse_string_array(field_name: str, body: str) -> list[str]:
    m = re.search(rf"{re.escape(field_name)}:\s*\[(.*?)\]", body, re.S)
    if not m:
        return []
    items = re.findall(r'"([^"]+)"', m.group(1))
    return items


def parse_personality_block(name: str, body: str) -> dict:
    def str_field(field: str) -> str:
        m = re.search(rf"{re.escape(field)}:\s*\"([^\"]+)\"", body)
        return m.group(1) if m else ""

    return {
        "name": str_field("name") or name,
        "version": str_field("version"),
        "description": str_field("description"),
        "states": parse_string_array("states", body),
        "events": parse_string_array("events", body),
        "cave_kinds": parse_string_array("cave_kinds", body),
        "initial_state": str_field("initial_state"),
        "terminal_states": parse_string_array("terminal_states", body),
    }


def parse_fst_personalities(text: str) -> dict:
    pattern = re.compile(
        r"pub\s+fn\s+([a-z0-9_]+)_personality\(\)\s*->\s*Personality\s*\{\s*\{(.*?)\}\s*\}",
        re.S,
    )
    personalities = []
    for fn_name, body in pattern.findall(text):
        personalities.append(parse_personality_block(fn_name.replace("_", "-"), body))

    return {
        "generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "source": str(FST_PERSONALITY.relative_to(ROOT)),
        "count": len(personalities),
        "personalities": personalities,
    }


def badge_svg(label: str, value: str, color: str) -> str:
    label_w = max(60, len(label) * 7 + 14)
    value_w = max(56, len(value) * 7 + 14)
    total = label_w + value_w
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{total}" height="20" role="img" aria-label="{label}: {value}">
  <linearGradient id="b" x2="0" y2="100%">
    <stop offset="0" stop-color="#fff" stop-opacity=".1"/>
    <stop offset="1" stop-opacity=".1"/>
  </linearGradient>
  <mask id="a"><rect width="{total}" height="20" rx="3" fill="#fff"/></mask>
  <g mask="url(#a)">
    <rect width="{label_w}" height="20" fill="#555"/>
    <rect x="{label_w}" width="{value_w}" height="20" fill="{color}"/>
    <rect width="{total}" height="20" fill="url(#b)"/>
  </g>
  <g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" font-size="11">
    <text x="{label_w/2}" y="15" fill="#010101" fill-opacity=".3">{label}</text>
    <text x="{label_w/2}" y="14">{label}</text>
    <text x="{label_w + value_w/2}" y="15" fill="#010101" fill-opacity=".3">{value}</text>
    <text x="{label_w + value_w/2}" y="14">{value}</text>
  </g>
</svg>
'''


def emit_markdown(capsule: dict, fst: dict) -> str:
    lines = []
    lines.append("# Cohesive Contract Index\n")
    lines.append("Generated isomorphic views from capsule + FST canonical sources.\n")
    lines.append("## Sources\n")
    lines.append(f"- `{capsule['source']}`\n")
    lines.append(f"- `{fst['source']}`\n")
    lines.append("\n")
    lines.append("![capsule-version](badges/capsule-version.svg) ")
    lines.append("![fst-network](badges/fst-network.svg) ")
    lines.append("![fst-personalities](badges/fst-personalities.svg)\n")

    lines.append("## Capsule Snapshot\n")
    lines.append(f"- Package: `{capsule['package']}@{capsule['version']}`\n")
    lines.append(f"- Types: `{capsule['types']['counts']['records']}` records, `{capsule['types']['counts']['enums']}` enums, `{capsule['types']['counts']['variants']}` variants\n")
    lines.append(f"- Capsule functions: `{len(capsule['capsule_functions'])}`\n")
    lines.append(f"- FST operations: `{', '.join(capsule['fst']['operations'])}`\n")

    lines.append("## FST Assurance Posture\n")
    lines.append("- `network_direct_allowed=false`\n")
    lines.append(f"- Allowed host surfaces: `{', '.join(capsule['fst']['surfaces'])}`\n")
    lines.append(f"- Assurance hooks: `{', '.join(capsule['fst']['assurance_functions'])}`\n")

    lines.append("## FST Personality Set\n")
    for p in fst["personalities"]:
        lines.append(f"- `{p['name']}@{p['version']}`: {p['description']}\n")

    lines.append("## Isomorphic Artifacts\n")
    lines.append("- `docs/contracts/capsule_contract.json`\n")
    lines.append("- `docs/contracts/fst_personalities.json`\n")
    lines.append("- `docs/contracts/CONTRACT_PRESENTATION.md`\n")
    lines.append("- `docs/contracts/isomorphic_cards.html`\n")
    lines.append("- `docs/contracts/badges/*.svg`\n")
    return "".join(lines)


def emit_presentation_md(capsule: dict, fst: dict) -> str:
    lines = []
    lines.append("# Cohesive Capsule + FST Contract Presentation\n\n")
    lines.append(f"Generated: {capsule['generated_at_utc']}\n\n")
    lines.append("## Slide 1 - Why this contract\n\n")
    lines.append("- One canonical contract source for capsule + FST runtime semantics\n")
    lines.append("- Emit synchronized views (docs, machine JSON, UI cards, badges)\n")
    lines.append("- Keep assurance posture explicit and replayable\n\n")

    lines.append("## Slide 2 - Capsule shape\n\n")
    lines.append(f"- Package: `{capsule['package']}@{capsule['version']}`\n")
    lines.append(f"- Records: `{capsule['types']['counts']['records']}`\n")
    lines.append(f"- Enums: `{capsule['types']['counts']['enums']}`\n")
    lines.append(f"- Variants: `{capsule['types']['counts']['variants']}`\n")
    lines.append(f"- Capsule API functions: `{len(capsule['capsule_functions'])}`\n\n")

    lines.append("## Slide 3 - FST assurance posture\n\n")
    lines.append("- `network_direct_allowed=false`\n")
    lines.append(f"- Allowed surfaces: `{', '.join(capsule['fst']['surfaces'])}`\n")
    lines.append(f"- Assurance hooks: `{', '.join(capsule['fst']['assurance_functions'])}`\n\n")

    lines.append("## Slide 4 - Personality set\n\n")
    for p in fst["personalities"]:
        lines.append(f"- `{p['name']}@{p['version']}`: {p['description']}\n")
    lines.append("\n")

    lines.append("## Slide 5 - Isomorphic outputs\n\n")
    lines.append("- `capsule_contract.json` (machine)\n")
    lines.append("- `fst_personalities.json` (machine)\n")
    lines.append("- `COHESIVE_CONTRACT_INDEX.md` (docs)\n")
    lines.append("- `isomorphic_cards.html` (UI cards)\n")
    lines.append("- `badges/*.svg` (status surfacing)\n")
    return "".join(lines)


def emit_html(capsule: dict, fst: dict) -> str:
    def esc(s: str) -> str:
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

    cards = []
    cards.append(f"""
    <article class=\"card\">
      <h2>Capsule Contract</h2>
      <p><strong>{esc(capsule['package'])}@{esc(capsule['version'])}</strong></p>
      <ul>
        <li>{capsule['types']['counts']['records']} records</li>
        <li>{capsule['types']['counts']['enums']} enums</li>
        <li>{capsule['types']['counts']['variants']} variants</li>
        <li>{len(capsule['capsule_functions'])} capsule functions</li>
      </ul>
    </article>
    """)

    cards.append(f"""
    <article class=\"card\">
      <h2>FST Assurance</h2>
      <p><strong>Direct network: denied</strong></p>
      <p>Surfaces: {esc(', '.join(capsule['fst']['surfaces']))}</p>
      <p>Hooks: {esc(', '.join(capsule['fst']['assurance_functions']))}</p>
    </article>
    """)

    for p in fst["personalities"]:
        cards.append(f"""
        <article class=\"card\">
          <h2>{esc(p['name'])} <small>{esc(p['version'])}</small></h2>
          <p>{esc(p['description'])}</p>
          <p><strong>States:</strong> {esc(', '.join(p['states']))}</p>
          <p><strong>Events:</strong> {esc(', '.join(p['events']))}</p>
          <p><strong>Cave kinds:</strong> {esc(', '.join(p['cave_kinds']))}</p>
        </article>
        """)

    return f"""<!doctype html>
<html lang=\"en\">
<head>
  <meta charset=\"utf-8\" />
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
  <title>Loci Cohesive Contract Cards</title>
  <style>
    :root {{
      --bg: #f4f7f8;
      --ink: #1b2a34;
      --muted: #5d6f7b;
      --line: #d8e0e5;
      --card: #ffffff;
      --accent: #0f766e;
    }}
    * {{ box-sizing: border-box; }}
    body {{ margin: 0; font-family: "IBM Plex Sans", "Avenir Next", "Segoe UI", sans-serif; background: radial-gradient(circle at 10% 0%, #e7f7f4, var(--bg)); color: var(--ink); }}
    .wrap {{ max-width: 1100px; margin: 32px auto; padding: 0 16px; }}
    h1 {{ margin: 0 0 8px; font-size: 2rem; }}
    .sub {{ color: var(--muted); margin-bottom: 20px; }}
    .grid {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 14px; }}
    .card {{ background: var(--card); border: 1px solid var(--line); border-radius: 14px; padding: 14px; box-shadow: 0 3px 10px rgba(0,0,0,.04); }}
    .card h2 {{ margin: 0 0 8px; font-size: 1.06rem; color: var(--accent); }}
    .card h2 small {{ color: var(--muted); font-weight: 500; }}
    .card p, .card li {{ font-size: .93rem; line-height: 1.35; }}
    .card ul {{ margin: 8px 0 0 18px; padding: 0; }}
  </style>
</head>
<body>
  <div class=\"wrap\">
    <h1>Loci Cohesive Contract</h1>
    <p class=\"sub\">Isomorphic view cards generated from capsule + FST sources</p>
    <section class=\"grid\">
      {''.join(cards)}
    </section>
  </div>
</body>
</html>
"""


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    BADGE_DIR.mkdir(parents=True, exist_ok=True)

    capsule = parse_capsule_wit(read_text(CAPSULE_WIT))
    fst = parse_fst_personalities(read_text(FST_PERSONALITY))

    (OUT_DIR / "capsule_contract.json").write_text(json.dumps(capsule, indent=2) + "\n", encoding="utf-8")
    (OUT_DIR / "fst_personalities.json").write_text(json.dumps(fst, indent=2) + "\n", encoding="utf-8")
    (OUT_DIR / "COHESIVE_CONTRACT_INDEX.md").write_text(emit_markdown(capsule, fst), encoding="utf-8")
    (OUT_DIR / "CONTRACT_PRESENTATION.md").write_text(emit_presentation_md(capsule, fst), encoding="utf-8")
    (OUT_DIR / "isomorphic_cards.html").write_text(emit_html(capsule, fst), encoding="utf-8")

    (BADGE_DIR / "capsule-version.svg").write_text(badge_svg("capsule", capsule["version"], "#0f766e"), encoding="utf-8")
    (BADGE_DIR / "fst-network.svg").write_text(badge_svg("fst-network", "denied", "#1d4ed8"), encoding="utf-8")
    (BADGE_DIR / "fst-personalities.svg").write_text(badge_svg("personalities", str(fst["count"]), "#7c3aed"), encoding="utf-8")

    print("generated_contract_views=1")
    print("- docs/contracts/capsule_contract.json")
    print("- docs/contracts/fst_personalities.json")
    print("- docs/contracts/COHESIVE_CONTRACT_INDEX.md")
    print("- docs/contracts/CONTRACT_PRESENTATION.md")
    print("- docs/contracts/isomorphic_cards.html")
    print("- docs/contracts/badges/*.svg")


if __name__ == "__main__":
    main()
