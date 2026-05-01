## 2025-02-14 - Cancel prompt message missing
**Learning:** Calling `clack.cancel()` without a message argument produces suboptimal UX and may lead to strict typing runtime errors in the `@clack/prompts` library.
**Action:** Always provide a descriptive string message when calling `clack.cancel()` (e.g., `clack.cancel('Cancelled.')`).
