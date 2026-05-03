# AI Capability Guide v0.1 (Canonical)

This is the authoritative AI-operability guide for `zploc/loci` v0.1.

## Preflight (Deterministic Runs)

Run these before any agent-assisted workflow:

```bash
moon update
moon check --deny-warn
moon info --target all && git diff --exit-code
moon fmt && git diff --exit-code
moon test --target all
(cd cli && bun test)
```

Notes:
- Native tests may require host support for toolchain/runtime features.
- CI is the release source of truth for cross-platform checks.
- If local native tests fail due host libc/thread/runtime constraints, use containerized execution (toolbox/distrobox) or a remote Linux builder, and treat local wasm-gc + CLI tests as the minimum fast loop.

### Distrobox native slice pattern

This repo includes a reusable distrobox profile and wrapper:

- `distrobox.ini` (`[loci-native]` profile)
- `scripts/distrobox-native.sh`
- `just` targets:
  - `just distrobox-create`
  - `just distrobox-enter`
  - `just distrobox-native-check`
  - `just distrobox-native-test`
  - `just distrobox-native-all`

## Feature Map (v0.1)

- Deterministic hashing: `hash/` (`@hash.Hash`)
- Tree sealing and sparse diff: `tree/` (`@tree.MerkinTree`, sparse/diff APIs)
- Core semantic model: `model/` (`passport`, `yata`, `resonance`, `semantic_router`)
- Store + OCI storage policies: `store/`, `storage/`
- Daemon workflows: `daemon/`
- CLI entrypoint: `cmd/main/` (native delegate), `cli/` (Bun frontend)
- AI locus contract surface: `_loci/chatgpt/` (canonical), `loci/chatgpt/` (legacy mirror)
- Conformance profiles: `conformance/`

## AI Task Recipes

1. Validate repository health
```bash
moon check --deny-warn
moon test --target wasm-gc
(cd cli && bun test)
```

2. Produce release artifacts locally
```bash
cd cli
bun run src/index.ts release build --target all --artifacts-dir ../artifacts/release-check
```

3. Inspect command contract for tool-calling agents
```bash
cd cli
bun run src/index.ts spec --format json
```

4. Run conformance-focused checks
```bash
moon test --target wasm-gc --package zploc/loci/conformance
```

## CLI Command Matrix (AI-Facing)

- `loci init`: initialize loci root/store
- `loci loci new <name>`: create locus scaffold
- `loci locus ls`: list loci
- `loci genius enter <locus> [--tier ...] [--export]`: session bootstrap
- `loci genius sign [--locus ...]`: append residue
- `loci genius trail <locus> [--depth N]`: timeline view
- `loci status`: quick workspace/state report
- `loci spec [--format json|markdown]`: machine-readable CLI contract
- `loci daemon ...`, `loci pack ...`, `loci app ...`: native delegate surface

## Expected Outputs (Key)

- `loci spec --format json`: stable command/flag/env schema for agent ingestion
- release build: `release-manifest.json`, wasm artifact(s), CLI bundles/binaries, `SHA256SUMS`
- triad/contract flows: JSON contract output with drift and byte-clean evidence fields

## Compatibility and Naming

- v0.1 public naming standard is `loci`.
- Historical `MERKIN_*` documentation is archival context only and must not be treated as canonical onboarding.
