# loci (zpc/merkin)

[![CI](https://github.com/zpc-sh/loci/actions/workflows/ci.yml/badge.svg)](https://github.com/zpc-sh/loci/actions/workflows/ci.yml)
[![Release](https://github.com/zpc-sh/loci/actions/workflows/release.yml/badge.svg)](https://github.com/zpc-sh/loci/actions/workflows/release.yml)
[![License: Apache-2.0](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](./LICENSE.mbt.md)
[![Stars](https://img.shields.io/github/stars/zpc-sh/loci)](https://github.com/zpc-sh/loci/stargazers)
[![Forks](https://img.shields.io/github/forks/zpc-sh/loci)](https://github.com/zpc-sh/loci/network/members)
[![Issues](https://img.shields.io/github/issues/zpc-sh/loci)](https://github.com/zpc-sh/loci/issues)

---

## 📝 1) Basic Project Info

### Project Name
- **Repository:** `zpc-sh/loci`
- **MoonBit module:** `zpc/merkin`
- **CLI package:** `@zpc/loci`

### Short Description
`loci` is a MoonBit-first, OCI-aligned substrate for deterministic hashing, tree sealing, storage policy control, daemon workflows, and Yata graph semantics.

### Long Description / Motivation
The project is built to support AI-native, content-addressed collaboration flows (“loci”) where work state can be structured, persisted, and replayed across sessions. It combines:
- deterministic content identity,
- policy-aware storage and OCI adapters,
- CLI/daemon operational surfaces,
- Yata drift and triad-contract workflows for cross-repo coordination.

It targets reproducible artifact behavior and portable execution (wasm-gc, wasm, and native), while keeping a host-side CLI/TUI entry point with Bun.

---

## ⚙️ 2) Technical Details

### Tech Stack / Frameworks
- **Primary language:** MoonBit (`.mbt`)
- **Secondary language:** TypeScript (Bun CLI)
- **Runtime/tooling:** MoonBit toolchain (`moon`), Bun, Zig (release workflow), GitHub Actions
- **Targets:** `wasm-gc`, `wasm`, `native`
- **Core domains:** hashing, bloom filters, tree/sparse/diff, model/envelope artifacts, store/storage, daemon runtime, triad contracts, conformance tests/benchmarks

### System Requirements
- Linux/macOS environment recommended for local workflows
- MoonBit CLI installed (`moon`)
- Bun installed (for `cli/` workflows)
- Zig (required in release pipeline)
- Git

### Dependencies / Packages
- MoonBit module: `zpc/merkin` (v`0.1.0`)
- Bun CLI package: `@zpc/loci` (v`0.1.0`)
- Major npm dependency:
  - `@clack/prompts`
- Internal package layout includes: `hash`, `bloom`, `gaussian`, `tree`, `model`, `store`, `storage`, `daemon`, `triad`, `conformance`, `cmd/main`, `wasm_entry`, `wasm_lib`

---

## 🚀 3) Setup & Installation

### Prerequisites
1. Install MoonBit: `moon`
2. Install Bun
3. (Optional for release tasks) Install Zig

### Installation Steps
```bash
git clone https://github.com/zpc-sh/loci.git
cd loci

# MoonBit checks/tests
moon check --target wasm-gc
moon test --target wasm-gc
moon test --target native --package zpc/merkin/simd
```

For Bun CLI:
```bash
cd cli
bun install
bun run build
```

### Configuration
- Default operational examples use repo-local paths such as:
  - `--store .merkin/store`
- Some Genius flows require attestation flags:
  - `--procsi-surface`, `--procsi-fingerprint`, `--app-ref`, `--app-hash`
- Bootstrap-only local flow is available via:
  - `--bootstrap-genius`

---

## 🧪 4) Usage

### How to Run the Project

Quick initialization:
```bash
moon run cmd/main -- ratio init --store .merkin/store
moon run cmd/main -- ratio loci new adversary --tags adversarial-ai,threat-intel --spirit "Threat analysis thread"
```

Daemon OCI/tree flows:
```bash
moon run cmd/main -- daemon oci capabilities --mode hybrid --targets local-1,oci-1
moon run cmd/main -- daemon oci put --mode receiver --targets local-1,oci-1 --payload hello --lane hot --path ingest/oci
moon run cmd/main -- daemon tree sparse --routes alpha/doc,beta/doc --tokens alpha
moon run cmd/main -- daemon tree diff --left-routes alpha/doc --right-routes beta/doc
```

Bun CLI:
```bash
cd cli
bun run dev
# or
bun run build
./dist/loci --help
```

### Example Inputs / Outputs
- Input example: `--payload hello --lane hot --path ingest/oci`
- Output behavior: receiver mode stores payload and updates in-memory daemon tree index; sparse/diff commands return token-filtered tree projections and differences.

### Screenshots / GIFs
- No screenshots or GIFs were detected in the repository.
- _Add visuals under `assets/` or `screenshots/` and link them here._

### Demo Links
- No hosted demo URL was found.
- _Add links for Netlify/Vercel/Heroku/self-hosted demo if available._

---

## ✨ 5) Features

### ✅ Key Features
- Deterministic hashing and content-addressed identity
- Tree ingest + epoch sealing
- Bloom-filtered sparse views and diff workflows
- Daemon CLI categories (`oci`, `tree`, `conv`, `yata`, `adapter`)
- OCI capability modes (`receiver`, `proxy`, `passthrough`, `hybrid`)
- Yata topology diagnostics and drift wire emission (`finger.plan.wasm`)
- Triad contract emission for Merkin/Mu/lang coordination
- CI artifact bundle generation (WASM, native, Bun CLI, manifests/checksums)

### ⚠️ Current Limitations / Coming Soon
- Several `ratio` and `genius` commands are still scaffold/pending for full filesystem behavior
- `ratio pack` serializer wiring is pending
- `cognitive` and `adapter validate` daemon surfaces are currently bridge-only in `cmd/main`

---

## 🤝 6) Contribution & Community

### How to Contribute
1. Fork the repository
2. Create a feature branch
3. Make changes with tests/docs updates
4. Run checks/tests locally
5. Open a Pull Request

### Issue / Bug Reporting
- Use GitHub Issues: https://github.com/zpc-sh/loci/issues
- Include:
  - reproduction steps
  - expected vs actual behavior
  - environment/toolchain details (`moon version`, OS, target)

### Community Links
- GitHub Discussions/Discord/Slack links were not found in-repo.
- _Add official community channels here._

---

## 🧪 7) Testing & Deployment

### Testing Instructions
```bash
moon check --target wasm-gc
moon test --target wasm-gc
moon test --target native --package zpc/merkin/simd
moon bench -p zpc/merkin/conformance
moon bench
```

### Build / Deployment Steps
- Local helper (`Justfile`) includes:
  - `just wasm-gc`
  - `just wasm`
  - `just cli` (native binary wrapper)
  - `just loci` (Bun single-file CLI bundle)
  - `just release vX.Y.Z`
- CI (`.github/workflows/ci.yml`) runs checks/tests and uploads build artifacts.
- Release (`.github/workflows/release.yml`) builds artifacts and publishes GitHub Releases on `v*` tags.

---

## 📈 8) Project Management

### Roadmap / Future Plans
Active scope (`docs/ROADMAP_SCOPE.md`):
- deterministic hashing + tree sealing
- storage/policy/daemon integration
- Yata protocol/addressing + regression coverage
- compiler diagnostics → Yata/Jules pipeline

De-scoped tracks are documented for reference in `docs/`.

### Changelog / Versioning
- No dedicated `CHANGELOG.md` detected.
- Current module/package version: `0.1.0` (`moon.mod.json`, `cli/package.json`)
- Releases are tag-driven via GitHub Actions (`v*`).

---

## 🏅 9) Badges

Included at top:
- CI status
- Release workflow status
- License
- Stars / Forks / Issues

_Optional additions you may want:_ MoonBit, Bun, WASM target badges.

---

## 📚 10) Meta Information

### License
- `moon.mod.json` declares: **Apache-2.0**
- Repository includes:
  - `LICENSE` (symbolic “Superposition License” text)
  - `LICENSE.mbt.md` (SPDX collapse state to Apache-2.0)
  - `LICENSE-EXECUTABLE.md`

### Acknowledgements
- MoonBit ecosystem and tooling
- Bun runtime/tooling
- OCI artifact model and related ecosystem inspirations
- Project docs under `docs/` for specification and operational guidance

### Contact Info
- Maintainer/author reference found in repository docs: **Loc Nguyen**
- Email referenced in docs: **l@zpc.sh**
- GitHub: **https://github.com/zpc-sh**
- _Add website/LinkedIn if you want them listed._

---

## Useful Docs Index

- `docs/DOCUMENTATION_INDEX.md`
- `docs/MERKIN_USER_MANUAL.md`
- `docs/DAEMON_CLI.md`
- `docs/TESTING_AND_BENCHMARKING.md`
- `docs/ROADMAP_SCOPE.md`
