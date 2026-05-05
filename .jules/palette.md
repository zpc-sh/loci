## 2026-05-05 - clack UX issue
**Learning:** The prompt logic in 'clack' cancels strictly, exiting the process directly, limiting robust UX recovery.
**Action:** Follow existing codebase patterns of handling user cancellation cleanly using clack.isCancel().
