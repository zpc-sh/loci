# Yata Shape Skill (v0)

Use this as a portable adapter for any AI system.

## Minimal flow
1. Tokenize local change surface into `tok`.
2. Run FST set: `pc,wf,tc,cb,cc`.
3. Compose decision via lattice `A<S<Q<D`.
4. Emit sparse loci tree (`allow/review/blocked`).
5. Emit promotion queue + attestation requirements.

## Portability
- Keep symbols stable.
- Map local tooling into `chg,tok,ctx,pol`.
- Keep repo-specific paths out of core contract.

## Non-goals
- No full forensic reconstruction.
- No hard dependency on git semantics.
