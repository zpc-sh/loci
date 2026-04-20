## 2024-XX-XX - Fix clack.cancel() missing message
**Learning:** In the clack/prompts library, `clack.cancel()` throws a runtime error if called without arguments in strict typing, but even if it doesn't, adding a helpful string like "Cancelled" provides better UX.
**Action:** Always provide a string message when calling `clack.cancel('...')`.
