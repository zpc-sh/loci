## 2024-05-04 - Handle clack cancellations gracefully
**Learning:** For terminal interactions using `@clack/prompts`, failing to provide a message to `clack.cancel()` can cause strict typing runtime errors. Additionally, checking for `clack.isCancel()` immediately after prompting ensures subsequent logic is safely bypassed, avoiding unintended side effects or broken prompt flows.
**Action:** Always provide a string (e.g., `'Cancelled.'`) to `clack.cancel()` and check `clack.isCancel()` immediately after each prompt, calling `process.exit(0)` if `true`.
