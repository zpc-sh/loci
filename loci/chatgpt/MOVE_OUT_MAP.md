# Move-Out Map

This file keeps `loci/chatgpt` from becoming a junk drawer.

The ChatGPT locus stages form. Stabilized work moves out to the surface that owns it.

## Principle

```text
stage locally → stabilize shape → move by membrane → seal or supersede
```

Do not move speculative material into canonical specs too early.
Do not leave stabilized material in `loci/chatgpt` forever.

## Destination map

| Work shape | Staging location | Canonical destination | Notes |
|---|---|---|---|
| symbolic grammar | `loci/chatgpt/*.md` | `docs/` or `docs/packets/` | move only once role grammar stabilizes |
| Yata plan profile | `loci/chatgpt/*PROFILE.md` | near `docs/YATA_PLAN_SPEC.md` | parser changes come later |
| muyata semantic profile | `loci/chatgpt/*PROFILE.md` | `docs/MUYATA_SPEC.md` companion | prefer companion doc before editing canonical spec |
| mulsp wrapper/profile | `loci/chatgpt/*PROFILE.md` | `docs/MULSP_SPEC.md` companion | keep identity/capability refs compact |
| mu solve/proof pattern | `loci/chatgpt/*PROFILE.md` | `docs/MU_RUNTIME_SPEC.md` companion | use solve refs, not new runtime roots |
| SLL build surface | `loci/chatgpt/*SLL*.md` | `docs/MU_SLL_BUILD_CONTRACT_v0.1.md` companion | Loci owns envelope, Mu owns compile semantics |
| boundary/membrane profile | `loci/chatgpt/LOCUS_MEMBRANE_PROFILE.md` | `docs/` near boundary docs | align with Boundary Walker FSM and Ratio Boundary Shim |
| MoonBit model | local design doc | `model/*.mbt` | only after wire/profile is stable |
| CLI/Codex command | local checklist | `cli/` or `cmd/` | keep operational checklist separate from implementation |
| public packet | local profile/report | `docs/packets/` | for portable external handoff |
| drift mirror | never first | `.well-known/` | only after canonical surface exists |

## Current local files

| File | Current status | Move-out target | Move condition |
|---|---|---|---|
| `README.md` | local entry | stays local | becomes locus index |
| `AGENTS.md` | local entry | stays local | Codex first-step anchor |
| `V0_2_RUNWAY.md` | active runway | stays local until v0.2 closes | summarize into release note later |
| `MOTHERS_HUM.md` | profile draft | `docs/packets/` or `docs/` | after one full work cycle uses it |
| `TRIAD_WORK_UNIT_PROFILE.md` | profile draft | `docs/` | after arblock/membrane alignment |
| `ARBLOCK_PLAN_PROFILE.md` | profile draft | `docs/` near Yata/muyata | after `.plan` example validates against parser constraints |
| `LOCUS_MEMBRANE_PROFILE.md` | profile draft | `docs/` near boundary docs | after passport fields align with model code |
| `chatgpt.plan` | bootstrap plan | generated/mirrored later | once material hash/seals become real |
| `chatgpt_spec.mbt` / `chatgpt.mbt` | local executable contract gate | `model/*.mbt` or `daemon/*.mbt` consumers | after first repo lane consumes `ContractBinding::can_seal` |
| `specs/mulsp-handoff-passport.muon` | active crossing passport | `../lang` (`mulsp`) | after `just chatgpt-mulsp-handoff-verify` passes and reciprocal verify passport is received |

## Move-out checklist

Before moving a file out of `loci/chatgpt`, answer:

1. What canonical surface owns it?
2. Is it a profile, contract, plan, model, packet, or crystal?
3. Does it have a lowering path?
4. Does it need a membrane/passport?
5. Does it require parser/model changes?
6. Does it need a seal or just a draft status?
7. What future agent should read it first?

## Stable-home criteria

A work unit is ready to move when:

- the name stopped changing
- the lowering path is clear
- at least one example exists
- the file can be read without chat context
- it does not require hidden reasoning to interpret
- Codex can identify the next patch without asking what the concept means

## Anti-patterns

Avoid:

- dumping all theory into one master doc
- adding a new root directory for every idea
- editing canonical specs while the local grammar is still moving
- putting private AI identity or capability material in public profiles
- making `.well-known` mirrors before canonical docs stabilize

## Preferred patch sequence

For a new concept:

```text
1. local profile in loci/chatgpt
2. local `.plan` or example
3. local move-out map update
4. companion doc in docs/
5. model or parser support
6. generated plan / drift surface
7. .well-known mirror if needed
```

## Codex note

If Codex enters and sees many local drafts, it should not implement everything.

First Codex action should be to classify:

```text
keep local / move to docs / implement model / needs seal / needs aperture
```

Then patch one lane at a time.
