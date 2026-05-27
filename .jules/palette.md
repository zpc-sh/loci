## 2024-05-27 - clack.cancel() Message requirement
**Learning:** Using `@clack/prompts`, calling `clack.cancel()` without an argument leads to poor UX in some environments and may cause strict type checking runtime errors down the line. Additionally, in multi-prompt sequences, `clack.isCancel()` must be explicitly handled for every prompt to prevent fallthrough on Ctrl+C.
**Action:** Always provide a descriptive string to `clack.cancel()`, e.g., `clack.cancel('Cancelled')`, and ensure `process.exit(0)` is called immediately after.
