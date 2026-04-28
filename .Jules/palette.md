## 2024-04-28 - Handle Clack Cancellations
**Learning:** Clack prompts must explicitly handle Ctrl+C cancellations by checking `clack.isCancel()` and calling `clack.cancel(msg)` followed by `process.exit(0)` to prevent silent continuation or runtime errors.
**Action:** Always add string message to `cancel()` and properly exit on cancel in multi-prompt sequences.
