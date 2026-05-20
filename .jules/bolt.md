## 2024-03-10 - Optimizing String Concatenation in Moonbit
**Learning:** Moonbit does not currently have a built-in `String::join` or `String::concat` for string arrays. The pattern of `out = out + items[i]` creates many intermediate strings and runs in O(N^2) time.
**Action:** Use `StringBuilder::new()` and `builder.write_string()` which runs in O(N) time for concatenating strings in loops in Moonbit.

## 2024-05-19 - Fast BFS Propagation for Tree Projections
**Learning:** In MoonBit, an O(N^2) loop checking presence in an expanding Map (`included.get(...) is Some(_)`) is very slow (12s for 2000 depth). Replacing it with an O(E) precomputation pass to map child-to-parent and an O(N) queue-based BFS propagation dramatically drops the time (to 0.12s).
**Action:** Always favor explicit work queues and adjacency maps over repeated N-passes for graph/tree propagation logic.
## 2024-05-19 - Parallelizing I/O Operations in Node/Bun Environments
**Learning:** Sequential `await` calls in loops, especially for filesystem I/O like `mkdir` and file reading, can create significant performance bottlenecks. While this is a well-known Node.js/Bun pattern, it is specifically relevant in initialization paths (`initLocus`, `initStore`) and data ingestion paths (`listResidues`) where multiple directories or files must be processed independently.
**Action:** When performing multiple independent I/O operations (e.g., directory creation, reading multiple files), always use `Promise.all` with `.map` to execute them concurrently instead of using sequential `await` in `for` loops.
