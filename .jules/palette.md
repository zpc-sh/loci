## 2026-05-13 - [Improve @clack/prompts CLI multi-prompt cancellation UX]
**Learning:** When using `@clack/prompts`, failing to check `isCancel` on sequential prompts or omitting a string message in `clack.cancel()` can lead to confusing CLI output, unhandled strict-typing runtime errors, and the user inadvertently continuing a wizard they intended to exit.
**Action:** Always verify `clack.isCancel()` on every prompt response and cleanly abort the process using `clack.cancel('Cancelled.')` followed by `process.exit(0)`.
