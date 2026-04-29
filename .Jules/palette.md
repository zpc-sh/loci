## 2024-05-01 - Cancel Handling in TUI
**Learning:** Calling `@clack/prompts` `cancel()` without a string message can lead to runtime typing issues or a poor UX. Furthermore, in multi-prompt sequences, not checking `clack.isCancel()` for every prompt and calling `process.exit(0)` means a user pressing Ctrl+C might simply be moved to the next prompt instead of safely aborting the command.
**Action:** Always provide a string argument like `"Cancelled."` to `clack.cancel()`. Always check `clack.isCancel()` for every input in a sequence and exit the process if true.
