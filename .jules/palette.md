## 2025-02-18 - Clack prompt cancellations
**Learning:** In multi-prompt sequences using `@clack/prompts`, pressing Ctrl+C does not abort the script automatically unless `isCancel` is checked and handled for *each* individual prompt.
**Action:** Always verify `clack.isCancel()` for every prompt in a sequence, provide a descriptive string (e.g. `clack.cancel("Cancelled")`) and explicitly call `process.exit(0)` to prevent the script from falling through.
