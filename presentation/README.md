# Loci Presentation (v0)

Tiny read-only sparse tree presentation surface for the Codex Pattern Kernel.

## Files
- `index.html`, `styles.css`, `app.js` — static UI
- `tree.json` — sparse tree payload consumed by renderer
- `tree.schema.json` — input contract
- `worker.js`, `wrangler.toml` — Cloudflare edge serving scaffold

## Local Serve
Use the tiny HTTP shim:

```bash
bun scripts/presentation_serve.ts
```

Then open `http://127.0.0.1:8788`.
