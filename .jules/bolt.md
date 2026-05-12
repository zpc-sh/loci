## 2024-03-10 - Optimizing String Concatenation in Moonbit
**Learning:** Moonbit does not currently have a built-in `String::join` or `String::concat` for string arrays. The pattern of `out = out + items[i]` creates many intermediate strings and runs in O(N^2) time.
**Action:** Use `StringBuilder::new()` and `builder.write_string()` which runs in O(N) time for concatenating strings in loops in Moonbit.

## 2024-05-19 - Fast BFS Propagation for Tree Projections
**Learning:** In MoonBit, an O(N^2) loop checking presence in an expanding Map (`included.get(...) is Some(_)`) is very slow (12s for 2000 depth). Replacing it with an O(E) precomputation pass to map child-to-parent and an O(N) queue-based BFS propagation dramatically drops the time (to 0.12s).
**Action:** Always favor explicit work queues and adjacency maps over repeated N-passes for graph/tree propagation logic.

## 2024-05-20 - Fast String Concatenation with write_char
**Learning:** In MoonBit, `write_char` is faster than `write_string` for single characters because it directly sets the byte buffer instead of checking string length and running copy loops. Replacing `b.write_string("|")` with `b.write_char('|')` is a free performance win on hot paths.
**Action:** When a literal being written to a `StringBuilder` or similar buffer is exactly 1 character (e.g. `|`, `=`, `,`, `/`), always use `write_char` instead of `write_string`.
