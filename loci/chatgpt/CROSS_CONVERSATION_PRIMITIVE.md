# Cross Conversation Primitive

Primitive identity: `loci.chatgpt.cross_conversation_primitive.v0`

Status: Codex feedback integrated as contract surface

Purpose: run one shared design conversation across ChatGPT and Codex inside this locus.

This primitive builds on `ConversationHost` (`daemon/conversation.mbt`) and is intended to be exposed through `cmd/main` as `conv design`.

## Why

- keep cross-agent design discussion replayable
- avoid ad-hoc side channels
- produce one `.plan` wire for design handoff and audit

## Command surface

Preferred command:

```bash
moon run cmd/main -- daemon conv design \
  --topic fsm-primitive \
  --chatgpt-content "propose policy primitive" \
  --codex-content "propose enforcement mapping" \
  --design-out loci/chatgpt/chatgpt-contracts.plan
```

Legacy action form:

```bash
moon run cmd/main -- daemon --action conv-design \
  --topic fsm-primitive \
  --chatgpt-content "propose policy primitive" \
  --codex-content "propose enforcement mapping"
```

## Output contract

The command should emit:

- `hall_id`
- `thread_id`
- `topic`
- `chatgpt_accepted`
- `codex_accepted`
- `design_plan_emitted`
- `design_plan_saved` when `--design-out` is set
- `design_plan_out` saved path
- emitted `.plan` wire as sanitized terminal-safe output

## Defaults

- chatgpt overlay: `chatgpt`
- codex overlay: `codex`
- authority: `substrate://loc/chatgpt`
- generator: `daemon.conversation.cross-design`
- note: `cross-agent design discussion`

## Current repo posture

At integration time:

- `ConversationHost` exists in `daemon/conversation.mbt`
- `conv design` was not observed on `master` through repository search
- this file therefore records the contract first, not an implementation claim

## Typed hole

```text
hole_id: H("cross-conversation-primitive" ++ "loci/chatgpt" ++ "v0.2")
anchor: loci/chatgpt/CROSS_CONVERSATION_PRIMITIVE.md
state: open
expected_type: daemon conversation primitive contract
```

Invariants:

- must use `ConversationHost` rather than an ad-hoc side channel
- must accept ChatGPT and Codex content as distinct turns or equivalent design inputs
- must emit one replayable `.plan` wire
- must support `--design-out` for saving the emitted plan
- must keep terminal output sanitized and replay-safe
- must not overwrite unrelated arblock plans silently

Candidate outputs:

- `daemon/conversation.mbt` additions for cross-design plan emission, if not already present
- `cmd/main` command plumbing for `daemon conv design`
- tests for accepted/rejected turns and saved plan output
- `loci/chatgpt/chatgpt-contracts.plan` update or derivative plan output

Verification:

- running the preferred command emits `hall_id`, `thread_id`, and `.plan` wire
- `--design-out` writes a valid `.plan` file
- both ChatGPT and Codex inputs appear as accepted or rejected statuses
- plan generator is `daemon.conversation.cross-design`

Move-out target:

```text
cmd/main + daemon/conversation.mbt for implementation
loci/chatgpt for profile and dogfood docs
```

Seal condition:

```text
first successful `conv design` output is committed or stored as an arblock/LMR leaf subject
```

## Relationship to ChatGPT contract arblock

This primitive is the missing transport between ChatGPT contracts and Codex implementation review.

It should become the standard way to hold one shared design thread across agents:

```text
ChatGPT form proposal
  + Codex enforcement/implementation mapping
  → ConversationHost thread
  → emitted `.plan`
  → arblock entry
  → later LMR leaf/root/proof
```

## Non-goals

- not a general chat system
- not a replacement for Yata holes
- not a hidden coordination channel
- not a persistence layer by itself

The primitive is a replayable cross-agent design turn that lowers into `.plan`.
