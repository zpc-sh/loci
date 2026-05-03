# Semantic Firewall Alignment: loci <-> mu (v0.1)

## Intent
Keep a shared semantic firewall contract across loci runtime boundaries and mu compiler/spec semantics.

## Loci Anchors (Concrete Runtime Surfaces)
- Router decisions: `allow|narrow|sandbox|quarantine|deny`
  - `model/passport.mbt`
  - `model/semantic_router.mbt`
- Boundary walking + contamination pressure
  - `loci_fsm/boundary.mbt`
  - `loci_fsm/attention.mbt`
- Quarantine lane implementation
  - `daemon/codecave.mbt`
- API emission of boundary mode/sanitization
  - `api/api.mbt`

## Mu Anchors (Semantic/Strictness Surfaces)
- Semantics reference
  - `../mu/spec/03_semantics.md`
- Strict compile/interface behavior
  - `../mu/spec/17_MU_CLI_SLL_CONTRACT.md`

## Alignment Contract
1. Boundary policy tags are canonical and stable:
   - `observe | sanitize | strict | quarantine`
2. Promotion from quarantine requires deterministic replay + explicit attestations.
3. Connector/agent ingress must pass through typed boundary signals before execution surfaces.
4. Strict mode in mu must remain compatible with loci quarantine semantics (fail-closed preference).

## Planned Tooling
- Add automated cross-repo contract check that validates policy tags and decision vocab are unchanged.
- Emit versioned `semantic_firewall_contract.json` for CI auditing.
