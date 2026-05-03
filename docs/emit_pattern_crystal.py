#!/usr/bin/env python3
"""
emit_pattern_crystal.py

Synthesize top-down Pactis contractual architecture with bottom-up loci
executable contract surfaces into a refined Pattern Crystal artifact.

Outputs:
- docs/contracts/pattern_crystal.json
- docs/contracts/PATTERN_CRYSTAL.md
"""

from __future__ import annotations

import json
import shutil
from pathlib import Path
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parent.parent
PACTIS_MATRIX = ROOT.parent / "pactis" / "docs" / "specifications" / "contract_matrix.jsonld"
CAPSULE_JSON = ROOT / "docs" / "contracts" / "capsule_contract.json"
FST_JSON = ROOT / "docs" / "contracts" / "fst_personalities.json"
OUT_DIR = ROOT / "docs" / "contracts"
LOCI_AGENT_OUT_DIR = ROOT / "_loci" / "codex-crystal"
DOT_LOCI_AGENT_OUT_DIR = ROOT / ".loci" / "codex-crystal"
LEGACY_LOCI_AGENT_OUT_DIR = ROOT / "loci" / "codex-crystal"


def load_json(path: Path, default: dict) -> dict:
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding="utf-8"))


def build_crystal() -> dict:
    pactis = load_json(PACTIS_MATRIX, {"contracts": []})
    capsule = load_json(CAPSULE_JSON, {})
    fst = load_json(FST_JSON, {"personalities": []})

    pactis_contracts = pactis.get("contracts", [])
    pactis_count = len(pactis_contracts)

    loci_fst_personalities = [p.get("name", "unknown") for p in fst.get("personalities", [])]

    crystal = {
        "kind": "loci.codex.pattern.crystal.v0",
        "generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "inputs": {
            "pactis_contract_matrix": str(PACTIS_MATRIX),
            "loci_capsule_contract": str(CAPSULE_JSON),
            "loci_fst_personalities": str(FST_JSON),
        },
        "lineage": {
            "top_down": {
                "name": "Pactis contractual architecture",
                "strength": "broad interface taxonomy and machine registry",
                "evidence": {
                    "contract_count": pactis_count,
                    "registry_kind": pactis.get("@type", "ContractMatrix"),
                },
            },
            "bottom_up": {
                "name": "Loci executable contract surfaces",
                "strength": "runtime-first, self-emitting contract views",
                "evidence": {
                    "capsule_functions": len(capsule.get("capsule_functions", [])),
                    "fst_personality_count": len(loci_fst_personalities),
                    "fst_personalities": loci_fst_personalities,
                    "network_direct_allowed": capsule.get("fst", {}).get("network_direct_allowed", False),
                },
            },
        },
        "crystal_pattern": {
            "name": "Contract Crystal Pattern",
            "definition": "A self-aggregating contract system where executable surfaces emit synchronized isomorphic views and continuously reconcile against a canonical machine registry.",
            "axioms": [
                "Executable truth emits documentation, not the reverse.",
                "Machine registry and runtime surfaces are dual anchors.",
                "Every contract slice has machine, human, and visual projections.",
                "Assurance posture is explicit, testable, and emitted.",
                "Drift is treated as a first-class incident with deterministic repair paths.",
            ],
            "planes": [
                {
                    "id": "registry-plane",
                    "purpose": "global contract map",
                    "artifacts": [
                        "contract_matrix.jsonld",
                        "capsule_contract.json",
                        "fst_personalities.json",
                        "pattern_crystal.json",
                    ],
                },
                {
                    "id": "execution-plane",
                    "purpose": "stateful contract realization",
                    "artifacts": [
                        "wit/capsule/capsule.wit",
                        "loci_fsm/*",
                        "daemon yata wasm-plan / triad-contract outputs",
                    ],
                },
                {
                    "id": "projection-plane",
                    "purpose": "isomorphic communication",
                    "artifacts": [
                        "COHESIVE_CONTRACT_INDEX.md",
                        "CONTRACT_PRESENTATION.md",
                        "isomorphic_cards.html",
                        "badges/*.svg",
                        "PATTERN_CRYSTAL.md",
                    ],
                },
            ],
        },
        "transmutation_map": [
            {
                "from": "Top-down spec cataloging",
                "to": "Bottom-up executable emission",
                "mechanism": "Bind contract entries to runtime emitters and generated projections",
            },
            {
                "from": "Static docs drift risk",
                "to": "Self-aggregating synchronized views",
                "mechanism": "Single-source generators for JSON/MD/HTML/SVG outputs",
            },
            {
                "from": "Implicit runtime policy",
                "to": "Explicit assurance contract",
                "mechanism": "FST assurance policy+claim types and emitted posture badges",
            },
        ],
        "adoption_protocol": [
            "1. Emit contract views from executable sources on every change.",
            "2. Reconcile with registry-plane entries (missing/extra/drift).",
            "3. Generate projection-plane artifacts for docs/UI/presentation.",
            "4. Gate releases on crystal integrity checks.",
        ],
    }
    return crystal


def to_markdown(crystal: dict) -> str:
    td = crystal["lineage"]["top_down"]
    bu = crystal["lineage"]["bottom_up"]
    cp = crystal["crystal_pattern"]

    lines = []
    lines.append("# Pattern Crystal (Codex)\n\n")
    lines.append("Status: synthesized bottom-up + top-down cohesive contract pattern.\n\n")
    lines.append(f"Generated: {crystal['generated_at_utc']}\n\n")

    lines.append("## Lineage Synthesis\n\n")
    lines.append(f"- Top-down lineage: **{td['name']}**\n")
    lines.append(f"  - Strength: {td['strength']}\n")
    lines.append(f"  - Evidence: `{td['evidence']['contract_count']}` registered contracts\n")
    lines.append(f"- Bottom-up lineage: **{bu['name']}**\n")
    lines.append(f"  - Strength: {bu['strength']}\n")
    lines.append(f"  - Evidence: `{bu['evidence']['capsule_functions']}` capsule functions, `{bu['evidence']['fst_personality_count']}` FST personalities\n")

    lines.append("\n## Crystal Definition\n\n")
    lines.append(f"{cp['definition']}\n\n")

    lines.append("## Axioms\n\n")
    for ax in cp["axioms"]:
        lines.append(f"- {ax}\n")

    lines.append("\n## Contract Planes\n\n")
    for plane in cp["planes"]:
        lines.append(f"- **{plane['id']}**: {plane['purpose']}\n")
        for art in plane["artifacts"]:
            lines.append(f"  - `{art}`\n")

    lines.append("\n## Transmutation Map\n\n")
    for t in crystal["transmutation_map"]:
        lines.append(f"- `{t['from']}` -> `{t['to']}` via {t['mechanism']}\n")

    lines.append("\n## Adoption Protocol\n\n")
    for step in crystal["adoption_protocol"]:
        lines.append(f"- {step}\n")

    lines.append("\n## Working Name\n\n")
    lines.append("- **Contract Crystal Pattern**\n")
    lines.append("- alias: **Codex Pattern Crystal**\n")

    return "".join(lines)


def emit_agent_mirror(crystal: dict) -> list[Path]:
    mirrored_dirs = [LOCI_AGENT_OUT_DIR]
    if DOT_LOCI_AGENT_OUT_DIR.parent.exists():
        mirrored_dirs.append(DOT_LOCI_AGENT_OUT_DIR)
    if LEGACY_LOCI_AGENT_OUT_DIR.parent.exists():
        mirrored_dirs.append(LEGACY_LOCI_AGENT_OUT_DIR)

    mirrored_files: list[Path] = []
    source_files = [
        OUT_DIR / "pattern_crystal.json",
        OUT_DIR / "PATTERN_CRYSTAL.md",
        OUT_DIR / "COHESIVE_CONTRACT_INDEX.md",
        OUT_DIR / "CONTRACT_PRESENTATION.md",
        OUT_DIR / "isomorphic_cards.html",
        OUT_DIR / "capsule_contract.json",
        OUT_DIR / "fst_personalities.json",
    ]

    for out_dir in mirrored_dirs:
        out_dir.mkdir(parents=True, exist_ok=True)
        badges_out = out_dir / "badges"
        badges_out.mkdir(parents=True, exist_ok=True)

        for src in source_files:
            if src.exists():
                dst = out_dir / src.name
                shutil.copy2(src, dst)
                mirrored_files.append(dst)

        for badge in (OUT_DIR / "badges").glob("*.svg"):
            dst = badges_out / badge.name
            shutil.copy2(badge, dst)
            mirrored_files.append(dst)

        manifest = {
            "kind": "loci.codex.crystal.mirror.v0",
            "generated_at_utc": crystal["generated_at_utc"],
            "source_dir": str(OUT_DIR.relative_to(ROOT)),
            "files": sorted([str(p.relative_to(ROOT)) for p in mirrored_files if out_dir in p.parents]),
            "note": "Mirror only. Canonical generated sources remain under docs/contracts.",
        }
        manifest_path = out_dir / "MIRROR_MANIFEST.json"
        manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        mirrored_files.append(manifest_path)
        sentinel_path = out_dir / "DO_NOT_DELETE.md"
        sentinel_path.write_text(
            "# Codex Crystal Mirror\n\n"
            "This directory is a generated mirror for AI dogfooding.\n\n"
            "- Canonical source: `docs/contracts/`\n"
            "- Canonical runtime mirror root: `_loci/`\n"
            "- Regenerate with: `python3 docs/emit_contract_views.py && python3 docs/emit_pattern_crystal.py`\n"
            "- Safe policy: treat this folder as persistent workspace state; do not auto-clean.\n",
            encoding="utf-8",
        )
        mirrored_files.append(sentinel_path)

    return mirrored_files


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    crystal = build_crystal()
    (OUT_DIR / "pattern_crystal.json").write_text(json.dumps(crystal, indent=2) + "\n", encoding="utf-8")
    (OUT_DIR / "PATTERN_CRYSTAL.md").write_text(to_markdown(crystal), encoding="utf-8")
    mirrored = emit_agent_mirror(crystal)

    print("generated_pattern_crystal=1")
    print("- docs/contracts/pattern_crystal.json")
    print("- docs/contracts/PATTERN_CRYSTAL.md")
    print(f"- mirrored={len(mirrored)}")
    print("- _loci/codex-crystal/")
    if DOT_LOCI_AGENT_OUT_DIR.parent.exists():
        print("- .loci/codex-crystal/")
    if LEGACY_LOCI_AGENT_OUT_DIR.parent.exists():
        print("- loci/codex-crystal/ (legacy mirror)")


if __name__ == "__main__":
    main()
