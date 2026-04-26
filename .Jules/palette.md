## 2026-04-22 - clack.cancel() UX Improvement
**Learning:** Calling `clack.cancel()` without arguments in the `@clack/prompts` TUI lacks visual feedback to the user and can cause strict typing issues.
**Action:** Always provide a message like `clack.cancel('Cancelled.')` to clearly indicate to the user that the operation has aborted.
