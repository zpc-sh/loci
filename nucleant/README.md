# Nucleant Workspace

This directory is the competition-facing emission surface for recursive repository walks.

Purpose:

- keep ongoing "what we built" output in one stable place
- avoid overloading the word `kernel` while a real Loci kernel is being carved out
- materialize isomorphic views (doc/spec/graph/test/proof/coverage) per walk

Primary command:

```bash
just nucleant-walk
```

Outputs are written to:

- `nucleant/runs/<run-ref>/`
- `nucleant/latest` (pointer file with latest run ref)

Run refs are material-derived identifiers, not wall-clock timestamps. The
competition-facing surface must not emit dates or timestamps; when causality is
needed, use sequence numbers, parent refs, hash manifests, and explicit receipt
chains.

Run bundle includes:

- command outputs (`moon check`, focused tests)
- contract binding artifacts copied from `_loci/chatgpt`
- hash manifest for emitted artifacts
- summary report for competition updates
- spot-check ledger for the small proof surface a reviewer can inspect without
  observing the whole recursive proof
