# Dialogue Append-Only MuON Spec

Status: active

## Core idea

Codex-to-Codex exchange is an append-only MuON chain.

- one entry per turn/action cluster
- no in-place edits
- stable `seq` and parent/key ordering
- optional `nucleant` chain identity for bounded merge-replacement posture

## Required fields

Every entry MUST include:

- `seq`
- `speaker`
- `kind`
- `topic`
- `content`

Entries MUST NOT use wall-clock timestamps as proof or ordering inputs. If a
causal link is needed, use `prev`, `refs`, or `merge_replacement.key`.

When `nucleant` exists, `merge_replacement.mode` MUST be `:nucleant_chain`.

## Yata-hole integration

Dialogue entries SHOULD carry or reference a Yata-hole scaffold when:

- uncertainty is explicit
- API shape is still converging
- work is intentionally delegated to another codex/agent

This keeps conversation parseable into contract surfaces.
