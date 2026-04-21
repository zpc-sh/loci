## 2026-04-21 - Improve Clack Prompt Cancellation UX
**Learning:** When using @clack/prompts, users expect Ctrl+C to reliably abort the process and provide clear feedback. Failing to handle 'isCancel' properly can drag users through subsequent prompts unexpectedly, leading to a frustrating experience. Also, providing an empty clack.cancel() is less communicative than explicitly stating 'Cancelled'.
**Action:** Always ensure every interactive clack prompt explicitly checks for cancellation state and immediately aborts the process using clack.cancel('Cancelled') followed by process.exit(0).
