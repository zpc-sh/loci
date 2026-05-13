## 2024-06-25 - Parallelizing fs operations in Bun
**Learning:** Sequential await loops for fs operations like `mkdir` can create unnecessary bottlenecks. Bun handles concurrent fs operations efficiently.
**Action:** Use `Promise.all` alongside `map` to parallelize multiple independent I/O tasks (e.g., creating multiple directories).
