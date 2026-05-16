## 2024-03-10 - Optimizing String Concatenation in Moonbit
**Learning:** Moonbit does not currently have a built-in `String::join` or `String::concat` for string arrays. The pattern of `out = out + items[i]` creates many intermediate strings and runs in O(N^2) time.
**Action:** Use `StringBuilder::new()` and `builder.write_string()` which runs in O(N) time for concatenating strings in loops in Moonbit.

## 2024-05-19 - Fast BFS Propagation for Tree Projections
**Learning:** In MoonBit, an O(N^2) loop checking presence in an expanding Map (`included.get(...) is Some(_)`) is very slow (12s for 2000 depth). Replacing it with an O(E) precomputation pass to map child-to-parent and an O(N) queue-based BFS propagation dramatically drops the time (to 0.12s).
**Action:** Always favor explicit work queues and adjacency maps over repeated N-passes for graph/tree propagation logic.

## 2024-05-16 - Parallelizing CLI store initializations and reads
**Learning:** Sequential await loops for IO operations in TypeScript/Bun, such as `for (const p of paths) await mkdir(p)` and `for (const f of files) ... await Bun.file().text()`, are slow and cause significant IO wait.
**Action:** Replace sequential IO loops with `Promise.all(array.map(async item => ...))` to parallelize these operations and improve overall performance. Ensure to use `.filter` to clean up possible nulls if needed instead of truthiness checks to be safer and avoid undefined leakage.
