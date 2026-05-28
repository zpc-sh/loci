## 2024-05-28 - TUI Prompt Cancellations

**Learning:** When using `@clack/prompts`, multi-prompt sequences can incorrectly fall through if `isCancel` is not checked for *every* individual prompt. Additionally, `clack.cancel()` should always receive a message string (e.g., `'Cancelled'`) to avoid strict typing errors and provide better UX.

**Action:** Ensure `isCancel` checks are present for all prompts in a sequence and that `clack.cancel()` always includes a string message.
