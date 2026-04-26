# loci (genius) — build system
# https://just.systems
#
# Usage:
#   just              build wasm-gc (default)
#   just test         full test suite
#   just release      full release pipeline (prompts for version)
#   just release v0.2.0

mulsp_priv  := "../lang/mulsp/priv"
muyata_priv := "../lang/muyata/priv"

wasm_gc_entry := "_build/wasm-gc/release/build/wasm_entry/wasm_entry.wasm"
wasm_entry    := "_build/wasm/release/build/wasm_entry/wasm_entry.wasm"
wasm_gc_lib   := "_build/wasm-gc/release/build/wasm_lib/wasm_lib.wasm"
wasm_lib_wasm := "_build/wasm/release/build/wasm_lib/wasm_lib.wasm"
native_exe    := "_build/native/release/build/cmd/main/main.exe"

# ── build ─────────────────────────────────────────────────────────────────────

# Default: wasm-gc entry + lib (AtomVM/Popcorn + wasmex-gc)
[group('build')]
default: wasm-gc

# wasm-gc: entry (_start + exports) and lib (no _start)
[group('build')]
wasm-gc:
    moon build --target wasm-gc --release --package zpc/genius/wasm_entry
    moon build --target wasm-gc --release --package zpc/genius/wasm_lib

# Standard wasm (WasmEdge / wasmex linear-memory)
[group('build')]
wasm:
    moon build --target wasm --release --package zpc/genius/wasm_entry
    moon build --target wasm --release --package zpc/genius/wasm_lib

# Both wasm variants
[group('build')]
wasm-all: wasm-gc wasm

# Native CLI binary → ./loci
[group('build')]
cli:
    moon build --target native --release --package zpc/genius/cmd/main
    cp {{native_exe}} loci
    @echo "CLI: ./loci  ($(du -sh loci | cut -f1))"

# Bun CLI bundle → ./dist/loci (single-file, no node_modules)
[group('build')]
loci:
    bun build cli/src/index.ts \
        --outfile dist/loci \
        --target bun \
        --minify \
        --sourcemap=none
    chmod +x dist/loci
    @echo "Bun CLI: ./dist/loci  ($(du -sh dist/loci | cut -f1))"

# ── test ──────────────────────────────────────────────────────────────────────

# Full suite: wasm-gc + native SIMD + CLI
[group('test')]
test: test-wasm test-simd test-cli

# Bun/TS CLI test suite (spec conformance + command integration)
[group('test')]
test-cli:
    cd cli && bun test

# wasm-gc only (fast)
[group('test')]
test-wasm:
    moon test --target wasm-gc

# Native SIMD package only
[group('test')]
test-simd:
    moon test --target native --package zpc/genius/simd

# Focused Yata verification suite
[group('test')]
test-yata:
    moon test --target wasm-gc --package zpc/genius/model

# Contract-focused suite: chatgpt + daemon + locus + conformance
[group('test')]
test-contracts:
    moon test --target wasm-gc --package zpc/genius/loci/chatgpt
    moon test --target wasm-gc --package zpc/genius/daemon
    moon test --target wasm-gc --package zpc/genius/locus
    moon test --target wasm-gc --package zpc/genius/conformance

# Coverage analysis: instrument run then emit report
[group('test')]
coverage:
    moon test --target wasm-gc --enable-coverage
    moon coverage analyze

# Type-check all packages (no link step)
[group('test')]
check:
    moon check --target wasm-gc

# SAT/SMT offloaded proof runner (see docs/archive/tools/moon-prove-offloaded.sh)
[group('test')]
prove-offloaded:
    docs/archive/tools/moon-prove-offloaded.sh storage

# ── release ───────────────────────────────────────────────────────────────────

# Full release pipeline: test → build all artifacts → seal triad contract
[group('release')]
release version="v0.1.0" zig-target="native":
    docs/archive/tools/release.sh --version {{version}} --zig-target {{zig-target}}

# Quick dist without running tests
[group('release')]
dist version="v0.1.0" zig-target="native":
    docs/archive/tools/release.sh --version {{version}} --zig-target {{zig-target}} --skip-tests

# ── priv: copy wasm artifacts into sibling repos ──────────────────────────────

# Copy wasm-gc entry to mulsp + muyata priv (AtomVM/Popcorn path)
[group('priv')]
priv: wasm-gc
    mkdir -p {{mulsp_priv}} {{muyata_priv}}
    cp {{wasm_gc_entry}} {{mulsp_priv}}/merkin.wasm
    cp {{wasm_gc_entry}} {{muyata_priv}}/merkin.wasm
    @echo "→ mulsp/priv/merkin.wasm  ($(du -sh {{mulsp_priv}}/merkin.wasm | cut -f1))"

# Copy wasm-gc lib to priv (wasmex-gc path)
[group('priv')]
priv-lib: wasm-gc
    mkdir -p {{mulsp_priv}} {{muyata_priv}}
    cp {{wasm_gc_lib}} {{mulsp_priv}}/merkin-lib.wasm
    cp {{wasm_gc_lib}} {{muyata_priv}}/merkin-lib.wasm

# Copy standard wasm to priv (wasmex linear-memory path)
[group('priv')]
priv-wasm: wasm
    mkdir -p {{mulsp_priv}} {{muyata_priv}}
    cp {{wasm_entry}} {{mulsp_priv}}/merkin.wasm
    cp {{wasm_entry}} {{muyata_priv}}/merkin.wasm

# ── CLI spec ──────────────────────────────────────────────────────────────────

# Emit the CLI spec as JSON to stdout
[group('cli')]
loci-spec:
    cd cli && bun run src/index.ts spec

# Regenerate docs/CLI_SPEC_v0.1.md from the live spec
[group('cli')]
loci-spec-docs:
    cd cli && bun run src/index.ts spec --format markdown --out ../docs/CLI_SPEC_v0.1.md
    @echo "Updated: docs/CLI_SPEC_v0.1.md"

# ── tools (archived — see docs/archive/tools/) ────────────────────────────────

# Compiler/runtime docs bundle for Mu language handoff
[group('tools')]
mu-lang-handoff:
    docs/archive/tools/mu-lang-compiler-docs-bundle.sh

# Emit finger.plan.wasm + drift summary using sibling repo refs
[group('tools')]
wasm-plan-drift:
    docs/archive/tools/yata-wasm-plan-drift-sync.sh

# Emit triad contract JSON + ABI/branch drift summary across genius/mu/lang
[group('tools')]
triad-contract-sync:
    docs/archive/tools/yata-triad-contract-sync.sh

# Generate ChatGPT-locus contract binding artifacts in MuON + docs
[group('tools')]
chatgpt-contract-bind:
    docs/archive/tools/chatgpt-contract-binding-generate.sh

# Append one entry into ChatGPT/Codex append-only MuON dialogue log
[group('tools')]
chatgpt-dialogue-append:
    docs/archive/tools/chatgpt-codex-dialogue-append.sh

# Verify strict mulsp handoff passport + bundle seals for codex pickup
[group('tools')]
chatgpt-mulsp-handoff-verify:
    docs/archive/tools/chatgpt-mulsp-handoff-verify.sh

# ── misc ──────────────────────────────────────────────────────────────────────

[group('misc')]
clean:
    moon clean
    rm -f loci
