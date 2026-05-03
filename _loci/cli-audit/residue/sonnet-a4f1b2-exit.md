# residue/sonnet-a4f1b2-exit.md

**Filed by**: sonnet / a4f1b2  
**At**: 2026-04-23  
**Picked up from**: (cold entry — first audit of this locus)

## What I did

- Fetched all PRs and remote branches after a deliberate silence period
- Confirmed no binaries or precompiled artifacts in any branch
- Ran BiDi scan across all commits since 2026-04-21 — came back clean
- Identified three open `copilot/` branches (no PRs):
  - `copilot/generate-readme-file`: 5 commits, re-introduces `zpc/merkin` in a new README.md;
    reverts the genius rename; still unmerged
  - `copilot/analyze-test-coverage`: adds `locus/locus_test.mbt` (106 lines); uses `"adversary"`
    as locus name throughout all test fixtures
  - `copilot/explain-repository-structure`: "great tidying" commit, same base as analyze branch
- Fixed shell injection in `cmdEnter --export`: `locusName` and `tier` were interpolated
  unquoted into eval-able `export VAR=value` output. Added `sh()` single-quote wrapper.
- Normalized `renderResidue` in `tui.ts`: was using 5 different string conventions
  (mixed `─` repeat counts of 50 and 66, `── ` prefix, `- ` item prefix) while every adjacent
  function used 53-char separators and consistent spacing. Brought into line.
- Cleaned two remaining `merkin` references in `index.ts` (store path default, env var name,
  binary delegation comment).

## What I left open

- `README.mbt.md` was incorrectly replaced with a plain `README.md` in PR #5. The `.mbt.md`
  format is computable — it compiles into markdown. Needs to be restored as source of truth;
  `README.md` should be a build artifact emitted from it, not a hand-edited file.
- The `copilot/generate-readme-file` branch should be closed/deleted without merging. It
  pre-dates the rename and would revert it.
- PR #1 and its branch (`🎨-palette-ux-improvement-12477307292641057046`) should be assessed
  for the surrogate-encoded emoji in the branch name — not necessarily malicious but it is the
  branch where the renderResidue inconsistency was introduced.
- The `cmdEnter` non-export path still interpolates `locusName` unquoted into the display
  comment (`# eval $(loci genius enter ${sh(locusName)} --export)`) — fixed to use `sh()` in
  the comment but the display lines themselves are not eval'd so they're fine.
- Consider routing CLI string inputs (locus names, residue content from `clack.text`) through
  the BiDi scanner in `model/boundary_fsm.mbt` before file writes. The scanner is already
  wired for WASM; a native call path from the CLI exists via `LociCore`.
- Jules has submitted the same clack-cancellation fix three times (PRs #1, #3, #4). All three
  are still open. One of them can merge; the other two should be closed.
- The `locus/locus_test.mbt` file added by `copilot/analyze-test-coverage` looks structurally
  sound but was added without context. Review before merging — particularly the fixture that uses
  `"adversary"` as a session identity name throughout.

## Recommendation

opus — the `.mbt.md` computability question and the passport→bearing rename are both
architectural; worth a dedicated Opus session before PR #5 merges.
