# Protocol namespace migration: `merkin.*` → `loci.*`

**Status**: Tracked, not yet executed.

## Background

The project was renamed from `merkin` to `loci` (branding, CLI flags, env vars, store paths).
However, the **wire-format kind strings** and **MIME media types** that appear in serialized
artifacts, test fixtures, and protocol parsers were intentionally left unchanged.

These are **protocol identifiers**, not branding. Changing them is a breaking wire-format change
that requires a version bump and coordinated migration.

## Affected identifiers

### Kind strings (YAML/text wire format)
| Current | Target | Locations |
|---------|--------|-----------|
| `kind: merkin.yata.plan` | `kind: loci.yata.plan` | `model/yata_protocol.mbt`, `model/yata_lineage.mbt`, `api/api.mbt`, many tests |
| `kind: merkin.boundary.stigmergy` | `kind: loci.boundary.stigmergy` | `model/boundary_fsm.mbt` |
| `generator=merkin.wasm.finger` | `generator=loci.wasm.finger` | `api/api.mbt` |

### JSON kind fields
| Current | Target | Locations |
|---------|--------|-----------|
| `"kind": "merkin.triad.contract"` | `"kind": "loci.triad.contract"` | `api/api.mbt`, tests |
| `"merkin.locus.adjoin.contract"` | `"loci.locus.adjoin.contract"` | `model/adjoin.mbt` |
| `"merkin.locus.crossing.passport"` | `"loci.locus.crossing.passport"` | `model/passport.mbt` |
| `"merkin.resonance.amf"` | `"loci.resonance.amf"` | `model/resonance.mbt` |
| `"merkin.semantic.router.decision"` | `"loci.semantic.router.decision"` | `model/semantic_router.mbt` |

### MIME media types
| Current | Target |
|---------|--------|
| `application/vnd.merkin.bloom.v1` | `application/vnd.loci.bloom.v1` |
| `application/vnd.merkin.tree.v1` | `application/vnd.loci.tree.v1` |
| `application/vnd.merkin.void.v1` | `application/vnd.loci.void.v1` |
| `application/vnd.merkin.artifact.v1+octet-stream` | `application/vnd.loci.artifact.v1+octet-stream` |
| `application/vnd.merkin.config.muon.v1` | `application/vnd.loci.config.muon.v1` |
| `application/vnd.merkin.cognitive.manifest.v1+json` | `application/vnd.loci.cognitive.manifest.v1+json` |

### Replication scope
| Current | Target |
|---------|--------|
| `merkin.replication.v1` | `loci.replication.v1` |

## Migration plan

When ready to execute:

1. **Bump `moon.mod.json` version** to `0.2.0`
2. **Update all kind strings and MIME types** in the source files above
3. **Update all test fixtures** that assert on these strings — search for `merkin.yata.plan` in `*_test.mbt`
4. **Add a compatibility shim** in `model/yata_protocol.mbt` parser to accept both `merkin.yata.plan`
   and `loci.yata.plan` during a transition window, then harden
5. **Update `finger.ts`** — already changed `kind: merkin.yata.plan` → `kind: loci.yata.plan` on
   the TS side; the MoonBit parser will reject this until the shim lands
6. **Run `moon test --update`** to refresh snapshot tests
7. **Tag a protocol version** in the wire format header if one doesn't exist

## Note on `finger.ts` divergence

The user already renamed `kind: merkin.yata.plan` → `kind: loci.yata.plan` in
`cli/src/sdk/ide/finger.ts`. This means the TS emitter and the MoonBit parser are currently
out of sync. The MoonBit parser in `model/yata_protocol.mbt` line 112 still expects
`kind: merkin.yata.plan` and will reject `loci.yata.plan` until the shim is added.

**Immediate action needed**: Either revert `finger.ts` or add the shim to the parser.
