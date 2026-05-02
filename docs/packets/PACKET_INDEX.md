# Packet Index

Recommended transfer order for new repo organization. Packets marked
"→ v0.2.0-rc1" are absorbed into this arc's implementation.

1. `LOCI_NEWS_CODECAVE_SPEC_v0.1.md` → v0.2.0-rc1 (`model/news_edition.mbt`, `daemon/codecave.mbt`)
2. `REPORTER_GENIUS_LOCI_FSM_SPEC_v0.1.md` (Mu/Lang territory; out of scope this arc)
3. `FINGER_PLAY_STORY_UPLINK_PROTOCOL_v0.1.md` (Mu/Lang territory; out of scope this arc)
4. `PACTIS_SPEC_API_SURVIVAL_MAP_v0.1.md` (federation adapter preserved; out of scope this arc)
5. `LOCI_SIX_SURFACES_AND_LIFECYCLE_v0.1.md` (informs ownership map; no code in this arc)
6. `LOCUS_ADJOIN_CONTRACT_v0.1.md` → v0.2.0-rc1 (`model/adjoin.mbt`)
7. `LOCUS_CROSSING_PASSPORT_v0.1.md` → v0.2.0-rc1 (`model/passport.mbt`, `model/boundary_fsm.mbt::cross`)
8. `NEWS_HELPER_EVENT_WIRE_v0.1.md` (reporter-side wire; Mu/Lang territory)
9. `NEWS_CODECAVE_BOOT_HOOK_v0.1.md` → v0.2.0-rc1 (`daemon/codecave.mbt::boot_hook`)
10. `cgn-minion-fsm-config.yaml` (blueprint; reporter FSM is Mu/Lang)
11. `cgn-agent-config.yaml` (blueprint; agent plumbing is Mu/Lang)
12. `MERKIN_RESEARCH_AND_GOVERNANCE_ONEPAGER_v0.1.md`
13. `OPENAI_INTAKE_SUMMARY_v0.1.md`

Additional v0.2.0-rc1 deliverables (not from this packet set):

- Resonance layer (AMF): `docs/RESONANCE_LAYER_SPEC_v0.1.md`, source
  `docs/new/prior-art-ai-music-format.md` → `model/resonance.mbt`,
  `model/resonance_composition.mbt`
- Mu/SLL build contract stub: `docs/MU_SLL_BUILD_CONTRACT_v0.1.md`,
  reference `docs/SLL_REFERENCE_v0.1.md` → `model/sll_build_contract.mbt`
- Semantic router contract stub: `docs/SEMANTIC_ROUTER_CONTRACT_v0.1.md`
  → `model/semantic_router.mbt` (shape + replayable decision artifacts;
  policy logic lives in the next arc)
- Five-tuple substrate identity + resonance extension:
  `model/procsi_identity.mbt`

Legacy/optional (if needed for comparison):

- `APB_SUBSTRATE_SPEC_v0.1.md`
- `PROVIDER_FIRST_RESPONSE_PLAYBOOK_v0.1.md`
