#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
REPO_ROOT="${1:-$ROOT_DIR}"
BUNDLE_LIST_REL="${2:-loci/chatgpt/specs/mulsp-handoff-bundle.sha256}"
PASSPORT_REL="${3:-loci/chatgpt/specs/mulsp-handoff-passport.muon}"

BUNDLE_LIST="$REPO_ROOT/$BUNDLE_LIST_REL"
PASSPORT="$REPO_ROOT/$PASSPORT_REL"

if [[ ! -f "$BUNDLE_LIST" ]]; then
  echo "missing_bundle_list=$BUNDLE_LIST_REL" >&2
  exit 2
fi

if [[ ! -f "$PASSPORT" ]]; then
  echo "missing_passport=$PASSPORT_REL" >&2
  exit 2
fi

if ! command -v sha256sum >/dev/null 2>&1; then
  echo "missing_tool=sha256sum" >&2
  exit 2
fi

(
  cd "$REPO_ROOT"
  sha256sum -c "$BUNDLE_LIST_REL"
)

required_lines=(
  'kind: :merkin_locus_crossing_passport'
  'target_locus: "genius://zpc/lang/mulsp"'
  'boundary_mode: :strict'
)

for line in "${required_lines[@]}"; do
  if ! grep -Fq "$line" "$PASSPORT"; then
    echo "passport_check_failed=$line" >&2
    exit 3
  fi
done

echo "handoff_verify=ok"
echo "repo_root=$REPO_ROOT"
echo "bundle_list=$BUNDLE_LIST_REL"
echo "passport=$PASSPORT_REL"
