## 2024-05-02 - Graceful TUI Prompts Cancellation
**Learning:** In terminal user interfaces using @clack/prompts, users expect Ctrl+C to cleanly abort multi-step flows without progressing to the next prompt or resulting in runtime issues from empty string inputs. We must check `isCancel` at every step and explicitly pass a message to `cancel()` to avoid strict typing errors and improve the exit experience.
**Action:** Always check `clack.isCancel()` immediately after every prompt resolution. If true, call `clack.cancel("Cancelled")` and `process.exit(0)` to exit cleanly.
