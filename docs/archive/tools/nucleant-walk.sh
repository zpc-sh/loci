#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHATGPT_DIR="$ROOT/loci/chatgpt"

material_run_id() {
  {
    printf 'nucleant-walk-v2\n'
    git -C "$ROOT" rev-parse HEAD 2>/dev/null || true
    git -C "$ROOT" status --short -- loci/chatgpt _loci/chatgpt nucleant/README.md nucleant/NUCLEANT_WALK_CONTRACT.md docs/archive/tools/nucleant-walk.sh docs/archive/tools/chatgpt-contract-binding-generate.sh 2>/dev/null || true
    find "$CHATGPT_DIR" "$ROOT/_loci/chatgpt" "$ROOT/nucleant/README.md" "$ROOT/nucleant/NUCLEANT_WALK_CONTRACT.md" "$ROOT/docs/archive/tools/nucleant-walk.sh" "$ROOT/docs/archive/tools/chatgpt-contract-binding-generate.sh" -type f \
      ! -path "$CHATGPT_DIR/GENERATED_CONTRACT_BINDING.md" \
      ! -path "$CHATGPT_DIR/specs/chatgpt-contract-binding.muon" \
      ! -path "$CHATGPT_DIR/tests/chatgpt-contracts.tests.muon" \
      ! -path "$CHATGPT_DIR/tests/chatgpt-contracts.results.muon" \
      ! -path "$CHATGPT_DIR/coverage/chatgpt-contracts.coverage.muon" \
      ! -path "$CHATGPT_DIR/proofs/chatgpt-contracts.proof-obligations.muon" \
      -print0 2>/dev/null \
      | sort -z \
      | xargs -0 sha256sum 2>/dev/null || true
  } | sha256sum | awk '{print "walk-" substr($1, 1, 16)}'
}

RUN_ID="${NUCLEANT_RUN_ID:-$(material_run_id)}"
RUN_DIR="$ROOT/nucleant/runs/$RUN_ID"

mkdir -p "$RUN_DIR"/{logs,artifacts}

echo "$RUN_ID" > "$ROOT/nucleant/latest"

{
  echo "run_id=$RUN_ID"
  echo "identity_basis=material_hash"
  echo "chronology=redacted"
  echo "root=$ROOT"
} > "$RUN_DIR/run.meta"

moon check --target wasm-gc > "$RUN_DIR/logs/moon-check.log" 2>&1
moon test --target wasm-gc --package zploc/loci/loci/chatgpt > "$RUN_DIR/logs/moon-test-chatgpt.log" 2>&1

"$ROOT/docs/archive/tools/chatgpt-contract-binding-generate.sh" "$CHATGPT_DIR" "$RUN_ID" > "$RUN_DIR/logs/chatgpt-contract-bind.log" 2>&1

copy_if_exists() {
  local src="$1"
  local dst="$2"
  if [[ -f "$src" ]]; then
    cp "$src" "$dst"
  else
    echo "missing_artifact=$src" >> "$RUN_DIR/logs/missing-artifacts.log"
  fi
}

copy_if_exists "$CHATGPT_DIR/specs/chatgpt-contract-binding.muon" "$RUN_DIR/artifacts/"
copy_if_exists "$CHATGPT_DIR/tests/chatgpt-contracts.tests.muon" "$RUN_DIR/artifacts/"
copy_if_exists "$CHATGPT_DIR/tests/chatgpt-contracts.results.muon" "$RUN_DIR/artifacts/"
copy_if_exists "$CHATGPT_DIR/coverage/chatgpt-contracts.coverage.muon" "$RUN_DIR/artifacts/"
copy_if_exists "$CHATGPT_DIR/proofs/chatgpt-contracts.proof-obligations.muon" "$RUN_DIR/artifacts/"
copy_if_exists "$CHATGPT_DIR/graphs/chatgpt-contracts.graph.json" "$RUN_DIR/artifacts/"
copy_if_exists "$CHATGPT_DIR/graphs/chatgpt-contracts.d3.json" "$RUN_DIR/artifacts/"
copy_if_exists "$CHATGPT_DIR/graphs/chatgpt-contracts.mermaid.md" "$RUN_DIR/artifacts/"
copy_if_exists "$CHATGPT_DIR/GENERATED_CONTRACT_BINDING.md" "$RUN_DIR/artifacts/"

PLAN_FILE="$CHATGPT_DIR/chatgpt-contracts.plan"
if [[ -f "$PLAN_FILE" ]]; then
  TOTAL_CONTRACTS="$(grep -c '^- H-' "$PLAN_FILE" || true)"
  READY_CONTRACTS="$(grep -c '^- H-.* ready=true' "$PLAN_FILE" || true)"
else
  TOTAL_CONTRACTS=0
  READY_CONTRACTS=0
  echo "missing_plan_file=$PLAN_FILE" >> "$RUN_DIR/logs/missing-artifacts.log"
fi
MOON_TEST_LINE="$(grep -E 'Total tests: [0-9]+, passed: [0-9]+, failed: [0-9]+\.' "$RUN_DIR/logs/moon-test-chatgpt.log" | tail -n 1 || true)"
if [[ -n "$MOON_TEST_LINE" ]]; then
  TEST_TOTAL="$(echo "$MOON_TEST_LINE" | sed -E 's/.*Total tests: ([0-9]+), passed: ([0-9]+), failed: ([0-9]+).*/\1/')"
  TEST_PASSED="$(echo "$MOON_TEST_LINE" | sed -E 's/.*Total tests: ([0-9]+), passed: ([0-9]+), failed: ([0-9]+).*/\2/')"
  TEST_FAILED="$(echo "$MOON_TEST_LINE" | sed -E 's/.*Total tests: ([0-9]+), passed: ([0-9]+), failed: ([0-9]+).*/\3/')"
  TEST_BLOCKED=0
else
  TEST_TOTAL="$(grep -c 'status:' "$CHATGPT_DIR/tests/chatgpt-contracts.results.muon" || true)"
  TEST_PASSED="$(grep -c 'status: :passed' "$CHATGPT_DIR/tests/chatgpt-contracts.results.muon" || true)"
  TEST_BLOCKED="$(grep -c 'status: :blocked' "$CHATGPT_DIR/tests/chatgpt-contracts.results.muon" || true)"
  TEST_FAILED=0
fi

if [[ "$TOTAL_CONTRACTS" -gt 0 ]]; then
  PLAN_COMPLETENESS_PCT="$(( READY_CONTRACTS * 100 / TOTAL_CONTRACTS ))"
else
  PLAN_COMPLETENESS_PCT=0
fi

if [[ "$TEST_TOTAL" -gt 0 ]]; then
  TEST_COMPLETENESS_PCT="$(( TEST_PASSED * 100 / TEST_TOTAL ))"
else
  TEST_COMPLETENESS_PCT=0
fi

PROOF_FILE="$CHATGPT_DIR/proofs/chatgpt-contracts.proof-obligations.muon"
if [[ -f "$PROOF_FILE" ]]; then
  PROOF_TOTAL="$(grep -c 'status: :' "$PROOF_FILE" || true)"
  PROOF_COVERED="$(grep -c 'status: :covered' "$PROOF_FILE" || true)"
  PROOF_OPEN="$(grep -c 'status: :open' "$PROOF_FILE" || true)"
  PROOF_BLOCKED="$(grep -c 'status: :blocked' "$PROOF_FILE" || true)"
  PROOF_FAILED="$(grep -c 'status: :failed' "$PROOF_FILE" || true)"
else
  PROOF_TOTAL=0
  PROOF_COVERED=0
  PROOF_OPEN=0
  PROOF_BLOCKED=0
  PROOF_FAILED=0
  echo "missing_proof_file=$PROOF_FILE" >> "$RUN_DIR/logs/missing-artifacts.log"
fi

PROOF_SEALED=false
if [[ "$PROOF_TOTAL" -gt 0 && "$PROOF_OPEN" -eq 0 && "$PROOF_BLOCKED" -eq 0 && "$PROOF_FAILED" -eq 0 ]]; then
  PROOF_SEALED=true
fi

IMPLEMENTATION_SIGNAL="green"
if [[ "$PLAN_COMPLETENESS_PCT" -lt 60 ]]; then
  IMPLEMENTATION_SIGNAL="amber"
fi
if [[ "$PLAN_COMPLETENESS_PCT" -lt 30 ]]; then
  IMPLEMENTATION_SIGNAL="red"
fi

SEAL_POSTURE="green"
if [[ "$TEST_FAILED" -gt 0 || "$PLAN_COMPLETENESS_PCT" -lt 60 ]]; then
  SEAL_POSTURE="red"
elif [[ "$PROOF_SEALED" != "true" || "$TEST_BLOCKED" -gt 0 ]]; then
  SEAL_POSTURE="amber"
fi

{
  echo "kind: :nucleant_completeness"
  echo "run_id: \"$RUN_ID\""
  echo "source_boundary: \"loci/chatgpt\""
  echo "stages:"
  echo "  plan: { total: $TOTAL_CONTRACTS, ready: $READY_CONTRACTS, completeness_pct: $PLAN_COMPLETENESS_PCT }"
  echo "  implementation: { signal: :$IMPLEMENTATION_SIGNAL, based_on: \"plan_ready_contract_ratio\" }"
  echo "  testing: { total: $TEST_TOTAL, passed: $TEST_PASSED, failed: $TEST_FAILED, blocked: $TEST_BLOCKED, completeness_pct: $TEST_COMPLETENESS_PCT }"
  echo "  proof: { total: $PROOF_TOTAL, covered: $PROOF_COVERED, open: $PROOF_OPEN, blocked: $PROOF_BLOCKED, failed: $PROOF_FAILED, sealed: $PROOF_SEALED }"
  echo "overall:"
  echo "  evidence_score_pct: $(( (PLAN_COMPLETENESS_PCT + TEST_COMPLETENESS_PCT) / 2 ))"
  echo "  seal_posture: :$SEAL_POSTURE"
  echo "  proof_sealed: $PROOF_SEALED"
} > "$RUN_DIR/completeness.muon"

(
  cd "$RUN_DIR/artifacts"
  if ls -1 >/dev/null 2>&1; then
    sha256sum * > "$RUN_DIR/artifacts.sha256"
  else
    : > "$RUN_DIR/artifacts.sha256"
  fi
)

{
  echo "# Nucleant Spot-Check Ledger"
  echo
  echo "run_ref: \`$RUN_ID\`"
  echo "identity_basis: \`material_hash\`"
  echo "chronology: \`:redacted\`"
  echo
  echo "## Contract Binding Nucleant"
  echo
  echo "- claim: contract surfaces bind to tests, coverage, and proof obligations before seal."
  echo "- files: \`loci/chatgpt/specs/chatgpt-contract-binding.muon\`, \`loci/chatgpt/tests/chatgpt-contracts.results.muon\`, \`loci/chatgpt/proofs/chatgpt-contracts.proof-obligations.muon\`"
  echo "- test signal: $TEST_PASSED/$TEST_TOTAL passed, $TEST_FAILED failed, $TEST_BLOCKED blocked"
  echo "- proof signal: $PROOF_COVERED/$PROOF_TOTAL covered, $PROOF_OPEN open, $PROOF_BLOCKED blocked"
  echo "- falsifier: a required proof obligation is open/blocked while the seal reports green."
  echo
  echo "## Async Boundary Nucleant"
  echo
  echo "- claim: the core stays synchronous; asynchronous effects are normalized into receipts at the boundary."
  echo "- files: \`loci/chatgpt/ASYNC_BOUNDARY_STANCE.md\`"
  echo "- falsifier: core contract evaluation waits on ambient async state instead of an explicit receipt."
  echo
  echo "## Append-Only Dialogue Nucleant"
  echo
  echo "- claim: ChatGPT/Codex dialogue is append-only, sequence-addressed, and date-free."
  echo "- files: \`loci/chatgpt/DIALOGUE_APPEND_ONLY_MUON_SPEC.md\`, \`loci/chatgpt/dialogue/chatgpt-codex.muonlog\`"
  echo "- falsifier: an entry relies on wall-clock ordering, self-attested identity, or in-place mutation."
  echo
  echo "## Event Walker Nucleant"
  echo
  echo "- claim: interpreter walkers and compiled/JIT lowerings consume the same event and receipt model."
  echo "- files: \`nucleant/NUCLEANT_WALK_CONTRACT.md\`"
  echo "- falsifier: interpreter and compiled paths accept different conflict-resolution facts."
} > "$RUN_DIR/SPOTCHECK.md"

{
  echo "# Nucleant Walk Summary"
  echo
  echo "- run_ref: \`$RUN_ID\`"
  echo "- identity_basis: \`material_hash\`"
  echo "- chronology: \`:redacted\`"
  echo "- scope: \`loci/chatgpt\` bounded recursive emission"
  echo "- checks: \`moon check --target wasm-gc\`"
  echo "- tests: \`moon test --target wasm-gc --package zploc/loci/loci/chatgpt\`"
  echo "- artifacts: docs/spec/test/proof/coverage/graph copied into \`nucleant/runs/$RUN_ID/artifacts\`"
  echo "- hash_manifest: \`nucleant/runs/$RUN_ID/artifacts.sha256\`"
  echo "- completeness: \`nucleant/runs/$RUN_ID/completeness.muon\`"
  echo "- spotcheck: \`nucleant/runs/$RUN_ID/SPOTCHECK.md\`"
  echo "- seal_posture: \`$SEAL_POSTURE\`"
} > "$RUN_DIR/SUMMARY.md"

echo "nucleant walk complete: $RUN_DIR"
