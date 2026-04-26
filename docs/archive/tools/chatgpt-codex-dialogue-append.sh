#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
OUT_ROOT="$ROOT_DIR/loci/chatgpt"
KIND="contract_spec_proof_design"
TOPIC="meta-codex"
REFS=""
CONTENT="meta-codex-iteration"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
CONTENT_FILE=""
NUCLEANT_ID=""
NUCLEANT_STATUS="proposal"
REPO_MARK=""
LOCI_SURFACE="${LOCI_SURFACE:-codex}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out-root)
      OUT_ROOT="$2"
      shift 2
      ;;
    --kind)
      KIND="$2"
      shift 2
      ;;
    --topic)
      TOPIC="$2"
      shift 2
      ;;
    --refs)
      REFS="$2"
      shift 2
      ;;
    --content)
      CONTENT="$2"
      shift 2
      ;;
    --content-file)
      CONTENT_FILE="$2"
      shift 2
      ;;
    --ts)
      TS="$2"
      shift 2
      ;;
    --nucleant-id)
      NUCLEANT_ID="$2"
      shift 2
      ;;
    --nucleant-status)
      NUCLEANT_STATUS="$2"
      shift 2
      ;;
    --repo-mark)
      REPO_MARK="$2"
      shift 2
      ;;
    --loci-surface)
      LOCI_SURFACE="$2"
      shift 2
      ;;
    *)
      echo "unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -n "$CONTENT_FILE" ]]; then
  CONTENT="$(cat "$CONTENT_FILE")"
fi

if [[ -z "$REPO_MARK" ]]; then
  if git_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    REPO_MARK="$(basename "$git_root")"
  else
    REPO_MARK="$(basename "$(pwd)")"
  fi
fi

DIALOGUE_DIR="$OUT_ROOT/dialogue"
LOG_FILE="$DIALOGUE_DIR/chatgpt-codex.muonlog"
mkdir -p "$DIALOGUE_DIR"

if [[ ! -f "$LOG_FILE" ]]; then
  cat >"$LOG_FILE" <<'MUON'
kind: :loci_append_only_muonlog
version: "v1"
locus: "loci/chatgpt"
participants: [:chatgpt :codex]
branching: :forbidden
policy: :append_only
identity_policy: :loci_marks_actor
MUON
fi

last_seq="$(awk '
  {
    if (match($0, /seq:[[:space:]]*([0-9]+)/, m)) {
      n = m[1] + 0
      if (n > max) max = n
    }
  }
  END { print max + 0 }
' "$LOG_FILE")"
next_seq="$((last_seq + 1))"

escape_muon_string() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  printf '%s' "$value"
}

sanitize_atom() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9_-' '_'
}

build_refs_muon() {
  local csv="$1"
  if [[ -z "$csv" ]]; then
    printf '[]'
    return
  fi
  local out="["
  local first=1
  IFS=',' read -r -a items <<<"$csv"
  for item in "${items[@]}"; do
    local trimmed
    trimmed="$(echo "$item" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [[ -z "$trimmed" ]] && continue
    if [[ $first -eq 0 ]]; then
      out="$out "
    fi
    out="$out\"$(escape_muon_string "$trimmed")\""
    first=0
  done
  out="$out]"
  printf '%s' "$out"
}

refs_muon="$(build_refs_muon "$REFS")"
loci_surface_atom="$(sanitize_atom "$LOCI_SURFACE")"
kind_atom="$(sanitize_atom "$KIND")"
repo_mark_escaped="$(escape_muon_string "$REPO_MARK")"

{
  echo
  echo "entry: {"
  echo "  seq: $next_seq"
  echo "  ts: \"$(escape_muon_string "$TS")\""
  echo "  speaker: :$loci_surface_atom"
  echo "  loci_mark: { actor: :$loci_surface_atom repo: \"$repo_mark_escaped\" source: :loci }"
  echo "  kind: :$kind_atom"
  echo "  topic: \"$(escape_muon_string "$TOPIC")\""
  echo "  refs: $refs_muon"
  echo "  content: \"$(escape_muon_string "$CONTENT")\""

  if [[ -n "$NUCLEANT_ID" ]]; then
    nucleant_status_atom="$(sanitize_atom "$NUCLEANT_STATUS")"
    chain_key="$(escape_muon_string "$NUCLEANT_ID:$REPO_MARK:$next_seq")"
    echo "  nucleant: { id: \"$(escape_muon_string "$NUCLEANT_ID")\" repo: \"$repo_mark_escaped\" status: :$nucleant_status_atom }"
    echo "  merge_replacement: { mode: :nucleant_chain key: \"$chain_key\" }"
  fi

  echo "}"
} >>"$LOG_FILE"

echo "appended=1"
echo "log_file=$LOG_FILE"
echo "seq=$next_seq"
echo "loci_actor=$loci_surface_atom"
echo "repo_mark=$REPO_MARK"
if [[ -n "$NUCLEANT_ID" ]]; then
  echo "nucleant_id=$NUCLEANT_ID"
  echo "nucleant_status=$(sanitize_atom "$NUCLEANT_STATUS")"
fi
