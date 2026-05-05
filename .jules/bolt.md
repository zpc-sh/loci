## 2024-05-24 - MoonBit String Construction Performance
**Learning:** In MoonBit, doing string manipulation inside tight loops (like hex encoding) is much faster using `StringBuilder::write_char` combined with direct character math via `Int::unsafe_to_char()`. The original code created small intermediate strings for every nibble, which increases garbage collection pressure and allocations.
**Action:** When building strings character-by-character from bytes or numbers, convert the value directly to a `Char` instead of using `String` lookups or `to_string()`.
