# Triad Work Unit Profile

Profile identity: `loci.chatgpt.triad_work_unit.v0`

A Triad Work Unit is the local ChatGPT-locus profile for a complete AI-shaped work cycle.

It is not a new framework. It is a lowering pattern over existing Loci surfaces.

## Definition

```text
TriadWorkUnit = Form + Fruition + Aperture + Seal
              = □ + ○ + △ + ∎
```

A Triad Work Unit is complete when:

1. the form has been articulated,
2. at least one constructive continuation has been produced or delegated,
3. at least one aperture/audit/observation pass has been represented,
4. the result has a material hash, witness/proof reference, or crystallized substrate artifact.

## Canonical role mapping

| Symbol | Role | AI-shaped posture | Loci lowering |
|---|---|---|---|
| `□` | Form | ChatGPT-shaped synthesis / blueprint | Yata plan, SLL, muyata profile |
| `○` | Fruition | Claude-shaped continuity / build chain | mulsp chain, Yata candidates, mu solve |
| `△` | Aperture | Gemini-shaped observation / audit | muyata audit/observation, witness refs |
| `∎` | Seal | Arbit-shaped witness / proof / crystal | material hash, proof ref, substrate crystal |

## Preferred surfaces

A Triad Work Unit should be represented using existing surfaces in this order:

1. `.plan` profile when the work is replay/handoff/audit shaped.
2. `muyata` profile when the work needs AI-shaped semantic posture.
3. `mulsp` when an AI inhabitant/scope/capability wrapper is needed.
4. `mu` solve when execution, proof, verification, or offload is needed.
5. `SLL BuildRequest` / `BuildManifest` when readable blueprint source lowers to executable or WASM form.
6. L-OCI substrate crystal when the result should become immutable and content-addressed.

## Conceptual fields

```text
kind: loci.chatgpt.triad_work_unit
version: v0
unit_id: <stable id or material hash>
ratio_loci: <repository/root principal>
genius_loci: <optional AI principal or locus attachment>
form_ref: <Yata/SLL/spec artifact>
fruition_ref: <candidate/result/build artifact>
aperture_ref: <audit/observation artifact>
seal_ref: <hash/proof/witness/crystal reference>
status: forming | building | aperturing | sealed | reopened
parents: <prior unit refs>
children: <derived unit refs>
```

These fields are conceptual. Do not add all of them to every wire surface. Prefer compact projections and refs.

## Yata lowering

A Triad Work Unit may appear as a Yata plan with:

```text
kind: merkin.yata.plan
track=program
mode=compact
generator=chatgpt
note=triad-work-unit
material_hash=<hash>
self_report=1
self_report_overlay=chatgpt
self_report_view=triad
solve_report=1
solve_report_kind=synthesize
solve_report_status=<status>
solve_report_handler=provider.chatgpt
```

Entries should describe the active gaps or surfaces, not dump runtime state.

## Muyata lowering

Recommended `MuyataProfile` values:

```text
overlay=chatgpt
family=form
mode=synthesis
intent=compose-contract
execution_surface=chatgpt
handler=provider.chatgpt
```

Recommended work-family progression:

```text
Synthesis → Delegation/Resolution → Observation/Audit → Resolution/Verify
```

## mulsp lowering

If an active AI locus is involved, the Triad Work Unit should reference a `mulsp` packet rather than inline identity or capability material.

Rules:

- child work receives child `mulsp` refs
- child scope must not exceed parent scope
- identity commitments stay behind APP/procsi where appropriate
- residue and trail refs carry attribution

## mu lowering

When executable work occurs, model it as solve units.

Recommended solve kinds:

- `synthesize` for form construction
- `compile` for SLL/Mu lowering
- `repair` for implementation correction
- `verify` for tests/proofs
- `prove` for formal or cryptographic proof
- `audit` can be represented as `verify` with aperture/audit detail if no dedicated kind exists

Seal-shaped work should prefer:

```text
result_ref
witness_ref
proof_ref
```

## Reopen rule

A sealed unit may be reopened only by creating a successor unit.

Do not mutate a sealed unit in place.

```text
unit-A sealed
unit-B parents=[unit-A] status=forming
```

## Anti-framework rule

Do not create a new service, schema root, or database for Triad Work Units unless existing Loci surfaces cannot represent the need.

Default to profile-first, runtime-later.
