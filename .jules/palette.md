## 2026-05-22 - TUI Prompt Cancellation Handling
**Learning:** When using `@clack/prompts`, failing to provide a message to `clack.cancel()` can cause poor UX or strict typing issues. Additionally, in multi-prompt sequences, not checking `clack.isCancel()` for every prompt and not exiting the process explicitly can cause the sequence to fall through and misbehave when a user hits Ctrl+C.
**Action:** Always provide a string message like `clack.cancel("Cancelled.")` and ensure `clack.isCancel(result)` followed by `process.exit(0)` is checked individually for *every* prompt in a multi-step flow.
