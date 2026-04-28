# genius loci

genius loci is a MoonBit substrate for deterministic hashing, tree sealing, storage policy control, daemon workflows, and Yata graph semantics.

## Documentation hub

If you're looking for "where everything is", start here:

- `docs/MERKIN_MASTER_DOCUMENT.md` — cohesive project-wide current-state reference
- `docs/MERKIN_USER_MANUAL.md` — practical usage and operations manual
- `docs/MERKIN_PACK_STANDARD_v0.1.md` — pack standard and implementation-state reference
- `docs/GIT_GHOST_HARDENING_RUNBOOK.md` — git byte-hygiene and hardening runbook
- `docs/RATIO_BOUNDARY_SHIM_SPEC_v0.1.md` — design for git boundary filtering
- `docs/MERKIN_COMPOSITION_PRIMITIVES_v0.1.md` — composition maneuvers (`consume|union|atop`) and invariants
- `docs/MERKIN_API_REFERENCE_v0.1.md` — consolidated API reference (library/CLI/daemon/WASM/Pactis alignment)
- `docs/YATA_CONTRACT_LANGUAGE_PROFILE_v0.1.md` — Yata contract language profile for compiler/runtime integrations
- `docs/BOUNDARY_WALKER_FSM_v0.1.md` — boundary FSM for bidi/ghost markup and stigmergy emission
- `docs/MERKIN_CLI_TUI_DEMONSTRATIONS_v0.1.md` — Bun/TS + MoonBit demo script and artifact walkthrough
- `docs/DOCUMENTATION_INDEX.md` — full documentation map by use-case
- `docs/ROADMAP_SCOPE.md` — active scope and de-scoped tracks
- `docs/LIBRARY_API_GUIDE.md` — library-first usage guide
- `docs/DAEMON_CLI.md` — CLI commands and flags
- `docs/YATA_MOON_JULES_PIPELINE.md` — moon build diagnostics -> Yata holes -> Jules tasks

> Note: docs prefixed `MERKIN_` are from the prior era and kept as-is for temporal locality.

## Fastest adoption path (lazy tree mode)

If you want the minimal approach, treat genius loci as a deterministic tree pipeline:

1. hash payload bytes with `@hash.Hash::of_bytes`
2. ingest ids into `@tree.MerkinTree`
3. seal epochs with `MerkinTree::seal`

Then adopt policy/daemon/Yata layers only when you need them.

## Repository layout

- `hash/` — deterministic digest primitives
- `bloom/` — bloom filter implementation and tests
- `gaussian/` — salience field implementation and tests
- `tree/` — tree, sparse projection, and diff logic
- `model/` — artifacts, envelopes, anchors, Yata graph models
- `store/` — in-memory artifact storage behavior
- `storage/` — queue + OCI storage adapters and policy logic
- `daemon/` — daemon runtime and conversation scaffolding
- `triad/` — typed triad-contract emission wrapper
- `locus/` — locus runtime (agent's view of a locus)
- `conformance/` — profile-based conformance and benchmark checks
- `cmd/main/` — CLI entry point
- `docs/` — specifications, API docs, and release docs

## Testing and benchmarking

Primary commands (when MoonBit tooling is available):

```bash
moon test
moon bench -p zpc/genius/conformance
moon bench
```

More detail: `docs/TESTING_AND_BENCHMARKING.md`.

<!-- BUILD_MATRIX_BEGIN -->
## Cognition work-cycle
| Symbol | Cognition | Role | Package | Status |
|--------|-----------|------|---------|--------|
| □ | **ChatGPT** | form | `zpc/genius/loci/chatgpt` | ✅ active |
| ○ | **Claude** | expand | `zpc/genius/loci/claude` | ✅ active |
| △ | **Gemini** | seal | `zpc/genius/loci/gemini` | 🗺️ planned |

## MoonBit build targets
| Target | Preferred | Runtimes | Status |
|--------|:---------:|----------|--------|
| `wasm-gc` | ⭐ | AtomVM, WasmEdge, wasmex-gc | ✅ |
| `wasm` |  | WasmEdge, wasmex (linear-memory) | ✅ |
| `native` |  | linux-x64, macos-arm64 | ✅ |
| `js` |  | Node.js, Bun | 🧪 experimental |

## Release platforms
| Platform | Runner | Artifact |
|----------|--------|----------|
| Linux x86-64 | `ubuntu-latest` | `loci-linux-x64` |
| macOS Apple Silicon | `macos-latest` | `loci-macos-arm64` |

## Release artifacts
| File | Description | Built by |
|------|-------------|----------|
| `loci-bun.js` | Bun CLI bundle (requires Bun runtime) | `bun build --target bun` |
| `loci-wasm-gc.wasm` | WebAssembly GC module (preferred runtime target) | `moon build --target wasm-gc` |
| `loci-linux-x64` | Self-contained CLI binary — Linux x86-64 | `bun build --compile --target bun-linux-x64` |
| `loci-macos-arm64` | Self-contained CLI binary — macOS Apple Silicon | `bun build --compile --target bun-darwin-arm64` |
| `SHA256SUMS` | SHA-256 checksums for all artifacts | `python3 (hashlib)` |

## Roadmap
> **Cognition compilation** (roadmap): Compile directly against a cognition's substrate — cross-compile loci packages per AI provider target  
> When stable WIT interfaces land, each cognition becomes a wasm component compiled against its own world

<!-- BUILD_MATRIX_END -->
