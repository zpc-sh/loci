## 2024-03-10 - Optimizing String Concatenation in Moonbit
**Learning:** Moonbit does not currently have a built-in `String::join` or `String::concat` for string arrays. The pattern of `out = out + items[i]` creates many intermediate strings and runs in O(N^2) time.
**Action:** Use `StringBuilder::new()` and `builder.write_string()` which runs in O(N) time for concatenating strings in loops in Moonbit.

## 2024-05-19 - Fast BFS Propagation for Tree Projections
**Learning:** In MoonBit, an O(N^2) loop checking presence in an expanding Map (`included.get(...) is Some(_)`) is very slow (12s for 2000 depth). Replacing it with an O(E) precomputation pass to map child-to-parent and an O(N) queue-based BFS propagation dramatically drops the time (to 0.12s).
**Action:** Always favor explicit work queues and adjacency maps over repeated N-passes for graph/tree propagation logic.

## 2024-05-17 - Optimize string concatenation for single characters
**Learning:** In MoonBit, `write_string` with a single-character literal (e.g., `write_string(",")`) is less efficient than `write_char` with a character literal (e.g., `write_char(',')`). While the semantic outcome is identical, using `write_char` avoids the overhead of checking string length and processing the UTF-16 bytes loop, directly buffering the character. Since string building is very common in serialization (e.g., JSON, logs, AMF), this minor change compounds.
**Action:** When working in MoonBit code that heavily relies on `StringBuilder`, actively look for instances of `b.write_string("x")` and convert them to `b.write_char('x')`.
