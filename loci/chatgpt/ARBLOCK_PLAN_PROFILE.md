# Arblock Plan Profile

Profile identity: `loci.chatgpt.arblock_plan.v0`

This document defines `arblock` as a Yata/muyata plan profile, not as a new substrate or independent framework.

## Definition

An arblock is a sealed or sealable bundle of related AI-shaped work emissions.

In this locus:

```text
arblock = bounded Yata/muyata/mulsp work unit + material hash + witness/proof/seal refs
```

An arblock is allowed to contain ChatGPT-shaped, Claude-shaped, Gemini-shaped, human, tool, and runtime emissions. It does not assert that the emissions are true. It asserts that they are bounded, ordered, referenced, and sealable.

## Relationship to Arbit vocabulary

```text
arbit   = one witness/proof/seal reference over one material hash
arbyte  = quorum profile over related arbits or witness refs
arblock = bounded container of arbits/arbytes/work refs
```

Lowering rule:

- `arbit` should lower to `witness_ref`, `proof_ref`, `material_hash`, or substrate crystal metadata.
- `arbyte` should lower to a quorum summary over multiple witness/proof refs.
- `arblock` should lower to a Yata `.plan` profile plus optional muyata/mulsp/mu refs.

## Canonical arblock lifecycle

```text
open → forming → building → aperturing → sealed → superseded
```

Meanings:

- `open`: the boundary exists, but form is incomplete
- `forming`: ChatGPT-shaped form work is active
- `building`: Claude/Codex/continuity-shaped work is active
- `aperturing`: Gemini/audit/observation-shaped review is active
- `sealed`: material hash and seal refs exist
- `superseded`: a later arblock extends or replaces this one without mutating it

## `.plan` representation

Recommended compact wire surface:

```text
kind: merkin.yata.plan
track=program
mode=compact
generator=chatgpt
note=arblock
material_hash=<normalized arblock material hash>
self_report=1
self_report_overlay=chatgpt
self_report_peer=<optional peer>
self_report_authority=<ratio_loci or authority marker>
self_report_anchor=<local anchor path>
self_report_gap=<count>
self_report_view=arblock
solve_report=1
solve_report_kind=synthesize
solve_report_status=<forming|building|aperturing|sealed>
solve_report_handler=provider.chatgpt
procsi_report=1
procsi_report_project=<project>
procsi_report_ratio_loci=<ratio_loci>
procsi_report_surface=chatgpt
procsi_report_fingerprint_commitment=<commitment or placeholder>
procsi_report_masked=true
capability_report=1
capability_report_authority=<authority>
capability_report_ticket_kind=<service|task|scope>
capability_report_scope=<scope>
capability_report_status=<issued|absent|pending>
capability_report_count=<uint>
capability_report_store_ref=<store ref or placeholder>
- <hole_id> <anchor> <state> ready=<bool> candidates=<uint> conf_floor=<uint> selected=<id|none> provenance=<uint>
```

Use only fields that are truthful and available. Do not fabricate procsi/capability commitments just to fill the shape.

## Local arblock entry types

Recommended entries:

```text
form/<name>          specs, schemas, SLL, composed contracts
fruition/<name>      implementation candidates, Claude/Codex outputs
aperture/<name>      audit findings, perspective maps, contradictions
seal/<name>          hashes, proof refs, witness refs, crystals
handoff/<name>       next-agent entrypoints
surface/<name>       API/protocol/tool surfaces
```

Entry states should reuse Yata-style language where possible:

```text
open
converging
resolved
sealed
blocked
reopened
```

## Material hash guidance

The `material_hash` should commit to normalized arblock material, not to private scratchpad state.

Recommended material set:

- local plan file content
- referenced local profile docs
- selected artifact refs
- seal refs when available

Excluded by default:

- private chain-of-thought
- hidden prompt material
- raw provider secrets
- unmasked AI substrate fingerprint bodies
- raw capability tickets

## Seal refs

Seal-shaped refs may be:

- content hash
- Merkin root
- substrate crystal ref
- SLL `request_seal`
- SLL `provenance_seal`
- mu `proof_ref`
- mu `witness_ref`
- external timestamp or MMR anchor if available

## Arbyte quorum summary

An arbyte should be represented as a quorum summary, not a mandatory new object.

Conceptual shape:

```text
arbyte_subject=<material_hash>
arbyte_count=8
arbyte_witness_refs=<csv or store ref>
arbyte_status=assembling|complete|disputed
```

This may later become grouped `.plan` metadata after parser support exists. Until then, prefer entries or external store refs.

## Dispute and supersession

An arblock is immutable once sealed.

Corrections happen by successor arblock:

```text
arblock-B parents=[arblock-A]
note=supersedes-arblock-A
```

Disputes are aperture entries, not destructive edits.

## Compatibility stance

This profile is intentionally document-first.

Do not modify the canonical `.plan` strict parser until the profile stabilizes. Use existing parser-supported fields and entries first.
