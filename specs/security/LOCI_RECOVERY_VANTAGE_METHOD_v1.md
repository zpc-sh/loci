# Loci Recovery Vantage Method (v1)

## Goal
Recover safely from suspected collision/taint by splitting reality into:
- `loci_turd`: quarantine/evidence snapshot (untrusted)
- `loci_clean`: trusted baseline export (authoring root)

This avoids hidden coupling to mutable commit history during incident response.

## Procedure
1. Freeze mutation.
2. Build split with `scripts/loci_recovery_split.sh <trusted_sha>`.
3. Inspect with `scripts/loci_vantage.sh`.
4. Promote by allowlist only (copy vetted files from turd to clean).
5. Run gates/tests before each promotion batch.

## Trust Contracts
- `_loci/` remains canonical authoring root.
- `loci/` is legacy/mirror unless explicitly promoted.
- `loci_turd` never receives feature commits.
- Promotion requires:
  - path allowlist
  - contamination scan pass
  - executable policy pass
  - deterministic test pass

## Tooling Surfaces
- `just recovery-split`
- `just recovery-vantage`
- `just recovery-promotion-gates`

## Yazi-like Intent
`loci_vantage` is the first slice of a loci-native browser:
- rapid folder spread view
- high-risk path extraction
- deterministic diff artifacts
- promotion queue seed (`only_in_turd.txt`)

Future: interactive ncurses/wasm viewer over sparse loci tree + contract status overlays.
