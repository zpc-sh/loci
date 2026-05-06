## 2024-05-15 - Clack Cancellation UX
**Learning:** When using `@clack/prompts`, failing to abort on `isCancel()` skips the rest of the multi-prompt sequence with weird blank residues instead of cleanly exiting, and calling `clack.cancel()` without a string message causes a strict typing runtime error.
**Action:** Always provide a string message to `clack.cancel()` (e.g. `clack.cancel("Operation cancelled.")`) and check `clack.isCancel()` for every prompt in a sequence to properly handle user `Ctrl+C` behavior.
