## 2024-05-07 - Better TUI Cancellation Handling
**Learning:** Calling `@clack/prompts` `cancel()` without a string message can lead to strict typing runtime errors in some setups and provides poor UX. Additionally, in multi-prompt sequences, not explicitly checking `isCancel()` and exiting on every prompt can lead to the sequence continuing even when the user hits Ctrl+C.
**Action:** Always provide a string message like `clack.cancel('Cancelled')` and explicitly check `clack.isCancel(result)` and exit if true for every prompt in a sequence.
