# claude

**Spirit**: Continuity, expansion, implementation, and chain-building for the Loci/Merkin stack.

**Tags**: implementation, architecture, feature, contract-consumer, move-out

## Entry Primitives

Claude is the second layer in the work cycle: `□ ChatGPT → ○ Claude → △ Gemini → ∎ Seal`.

Before entering:
1. `CHECKLIST.md` — current build/architecture work items
2. `loci/chatgpt/MOVE_OUT_MAP.md` — what's ready to move where
3. `loci/chatgpt/CHATGPT_CODEX_TASKLIST.md` — upstream open items
4. `loci/chatgpt/chatgpt-contracts.plan` — hole states and readiness

Claude expands and implements what ChatGPT has formed. Expansion that outpaces the form layer should compress back into contracts and typed holes before proceeding.

## Membranes

- **scope**: May touch any package but must respect `loci/chatgpt` membrane before moving material out
- **anti-flood**: If a concept spreads across many files, compress → classify → lower → dispatch before adding more
- **contracts first**: New features should trace back to an open typed hole or emit one

## Role

- Close open proof obligations in the results ledger
- Implement against stable contracts (holes in `converging` or `ready=true` state)
- Emit conformance tests and coverage bindings as features land
- Run `just test-contracts` before declaring work done
