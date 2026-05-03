# cli-audit

**Spirit**: Track anomalies in the CLI/TUI layer — the only module written in TypeScript and the
primary surface where external influence can enter.

**Tags**: security, cli, tui, stigmergy, shell-safety

## Why this locus exists

`cli/` is categorically different from the rest of the substrate. Everything in MoonBit (hash,
tree, model, daemon, storage) has no string interpolation into shell contexts, no eval-able output,
no emoji in identifiers. The TypeScript layer is the gap. It is also the layer that Jules and
Copilot have repeatedly touched.

Before entering this locus, read:
1. `residue/sonnet-a4f1b2-exit.md` — first audit session findings (2026-04-23)
2. The commit at `73b91daa` (PR #1 branch head) — where the pattern was first visible

## What to look for

- **Shell output designed to be eval'd**: `--export` flag emits `export VAR=value`. Any
  user-controlled value reaching that path without quoting is a shell injection vector.
- **String styling inconsistency**: `renderResidue` in `tui.ts` used 5 different conventions
  in 12 lines while every adjacent function was uniform. Inconsistency at this density in a
  small, focused file is a signal, not a coincidence.
- **Hidden Unicode in identifiers**: PR #1 branch name contained surrogate-encoded emoji
  (`🎨`). The boundary FSM BiDi scanner covers file content; branch names are outside
  that perimeter.
- **Copilot branches reverting the rename**: `copilot/generate-readme-file` generated a README
  that re-introduced `zpc/merkin` after the genius rename. No PR was opened — the branch just
  sat ready.

## Membranes

- **scope**: BOUND to `cli/src/` only. The MoonBit substrate is not in scope here.
- **do not merge copilot branches** into master without full diff review against the rename state.
- **eval-able output** from any command must shell-quote all user-controlled values. The `sh()`
  helper in `genius.ts` is the single point of truth for this.

## Affordances

- Read `cli/src/tui.ts` and `cli/src/commands/genius.ts` together — they are the render/action pair
- The BiDi/ghost scanner lives in `model/boundary_fsm.mbt`; consider wiring CLI string inputs
  through it before they reach file writes or shell output
- Jules PRs follow a template; their diffs are small and mechanical. Anything structural in a
  Jules PR is unexpected.
