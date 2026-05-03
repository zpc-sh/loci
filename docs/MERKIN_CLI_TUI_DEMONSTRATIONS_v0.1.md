# Loci CLI/TUI Demonstrations v0.1

Self-contained demo flows for the Bun/TS `loci` surface and MoonBit-native `loci` daemon workflows.

Date baseline: `2026-04-19`.

## 1) What This Demonstrates

- host-side `loci` CLI/TUI lifecycle (`init`, `loci`, `genius`, `status`)
- delegation from Bun surface into native MoonBit daemon workflows
- release/CI artifacts (`loci.wasm`, `loci-lib.wasm`, native `loci`, bundled `loci`)

## 2) Local Setup

From repo root:

```bash
moon check --target wasm-gc
moon test --target wasm-gc
```

For Bun CLI:

```bash
cd cli
bun install
bun run build
./dist/loci --help
```

## 3) Demo A: Loci Bootstrap and Session Signaling

```bash
# from repo root
bun run cli/src/index.ts init
bun run cli/src/index.ts loci new adversary --tags threat-intel,ai
bun run cli/src/index.ts genius enter adversary --export
bun run cli/src/index.ts genius sign "Captured boundary notes"
bun run cli/src/index.ts status
```

Expected outcome:

- locus scaffold information printed
- enter preamble + environment export lines
- residue record and status overview output

## 4) Demo B: Daemon + Yata from Bun Surface

```bash
bun run cli/src/index.ts daemon yata topology --yata-branch-factor 5 --yata-max-children 3
bun run cli/src/index.ts daemon yata wasm-plan --routes alpha/doc,beta/doc --tokens alpha --drift-peers mu:abc,muyata:def
```

Expected outcome:

- topology stats in deterministic key/value output
- compact `finger.plan.wasm` wire
- paired `loci.boundary.stigmergy` wire
- attention gradient fields (`boundary_ticks`, `boundary_attention_score`, `boundary_attention_gradient`, `boundary_attention_saturated`)

## 5) Demo C: Native MoonBit CLI Equivalence

```bash
moon run cmd/main -- daemon yata wasm-plan --routes alpha/doc,beta/doc --tokens alpha --drift-peers mu:abc,muyata:def
moon run cmd/main -- daemon yata triad-contract --routes alpha/doc,beta/doc --tokens alpha --drift-peers mu:abc,lang:def --loci-head aaa --mu-head bbb --lang-head ccc
```

Use this to show Bun host surface and MoonBit native output consistency.

## 6) GitHub Actions Artifact Lanes

CI (`.github/workflows/ci.yml`):

- runs tests
- builds MoonBit artifacts + Bun bundle
- uploads `loci-ci-artifacts-<sha>` containing:
  - `loci.wasm`
  - `loci-lib.wasm`
  - `loci` (native, when produced)
  - `loci` (bundled Bun CLI)
  - `SHA256SUMS`

Release (`.github/workflows/release.yml`):

- runs on `v*` tags
- executes release builder
- attaches bundled assets to GitHub Release

## 7) Judge-Friendly Script (Quick Cut)

```bash
moon check --target wasm-gc
moon test api/api_test.mbt --target wasm-gc
bun run cli/src/index.ts status
bun run cli/src/index.ts daemon yata wasm-plan --routes alpha/doc,beta/doc --tokens alpha --drift-peers mu:abc,muyata:def
```

This sequence proves:

- core build health
- boundary/FSM drift output
- working host-side CLI/TUI layer
