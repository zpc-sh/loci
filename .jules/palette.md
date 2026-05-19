## 2025-05-19 - Proper handling of clack prompts cancellation in multi-prompt sequences
**Learning:** When using `@clack/prompts`, failing to explicitly check `clack.isCancel()` at every prompt step and exiting (`process.exit(0)`) leads to the sequence incorrectly falling through when a user presses Ctrl-C. Also, calling `clack.cancel()` without a message string causes runtime type errors.
**Action:** Always provide a message to `clack.cancel('Cancelled.')` and check for cancellation on *every* prompt in a multi-prompt sequence to ensure graceful exit on Ctrl-C.
