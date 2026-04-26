# F002 — Root Lineage Move-Out Location

Fill identity: `loci.claude.arblock.0001.fill.F002`

Fills hole: `H-C001-002` from `loci.chatgpt.contract.root_lineage.v0`

Status: converging

## Hole restatement

Where does the root lineage document eventually live? Constraints:

- must not create a new top-level framework
- should likely be `docs/` or a packet only after the arblock stabilizes
- must keep a local pointer in `loci/chatgpt`

## Candidate

```text
canonical destination: docs/ROOT_LINEAGE.md
local copy stays at:   loci/chatgpt/ROOT_LINEAGE.md (or pointer to docs/)
move condition:        after F001 is accepted and H-C001-001 is resolved
boundary mode:         observe until then
```

The local file `loci/chatgpt/ROOT_LINEAGE.md` already exists and is stable. When H-C001-001 is resolved, copy it to `docs/ROOT_LINEAGE.md` with a membrane crossing record and leave a pointer at the local path.

## Evidence

- `loci/chatgpt/MOVE_OUT_MAP.md` already maps symbolic grammar material to `docs/` as the destination.
- `ROOT_LINEAGE.md` is not symbolic grammar — it is foundational lineage. `docs/` is still appropriate.
- No new root directory is needed.

## Invariant check

| Invariant | Result |
|---|---|
| does not create a new top-level framework | pass |
| goes to docs/ or packet | pass — docs/ is the candidate |
| local ChatGPT pointer preserved | pass — stays at loci/chatgpt/ROOT_LINEAGE.md |

## Confidence

90

## Notes

Low uncertainty. The only open question is whether a separate `docs/packets/ROOT_LINEAGE_PACKET.md` is preferred over `docs/ROOT_LINEAGE.md`. A direct `docs/` path is simpler and more discoverable. Packets are for portable external handoff; lineage is internal canonical.
