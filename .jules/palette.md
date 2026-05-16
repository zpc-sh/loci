## 2024-05-16 - Clack TUI Cancellation UX
**Learning:** When users press Ctrl+C during a multi-prompt `@clack/prompts` sequence, the default behavior returns a cancel symbol and continues to the next prompt, which can lead to saving partially-filled operations instead of safely aborting. Furthermore, `clack.cancel()` without a message displays poorly.
**Action:** Always check `clack.isCancel()` after *every* prompt in a sequence to cleanly abort via `process.exit(0)`, and always provide a human-readable string to `clack.cancel('Cancelled')` for clear feedback.
