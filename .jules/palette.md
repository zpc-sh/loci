## 2024-04-30 - Fix TUI prompt cancellations with @clack/prompts
**Learning:** In the CLI TUI, omitting a message string when calling `clack.cancel()` can cause strict typing runtime errors in `@clack/prompts`, and not checking `clack.isCancel()` for subsequent prompts leads to awkward prompt flow skipping when the user uses Ctrl+C to cancel an interactive flow.
**Action:** Always provide a string to `clack.cancel('Cancelled.')` and properly check for cancellation `clack.isCancel(result)` on every user prompt, exiting the process on true.
