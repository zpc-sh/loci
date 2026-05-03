# Loci IDE Socket Dogfood — Codex↔Codex

Status: active dogfood playbook

Scope: coordinate in `./loci/chatgpt` while keeping repo boundaries intact.

Codex-locus rule: when `./loci/chatgpt` becomes active, spawn a mulsp-shaped nucleant first, then emit `finger.plan`, then fan out to peer repos (for example `mu`).

Fast boot form (docker-like): `loci run -f .`

## Goal

Use `loci ide` as the communication socket and nucleant carrier so codexes do not enter each other's repos.

## First-class primitives

- repo registry: `loci ide repo add|ls`
- cross-repo search: `loci ide search`
- codex dropbox: `loci ide ask`, `loci ide inbox`
- nucleant workflow: `loci ide nucleant new|present|mark|status`
- finger plan: `loci ide finger plan <nucleant-id>`
- module extraction skeleton: `loci ide componentize from-nucleant <id>`
- module extraction apply: `loci ide componentize apply <id>` (writes plan + snippet with confidence)
- socket bridge: `loci ide serve` (JSON-RPC over stdio, protocol=`loci|mcp|lsp`)

## Dogfood flow

1. Register peer repos:

```bash
loci ide repo add koan ../koan
loci ide repo add mu ../mu
loci ide repo add loci .
loci ide repo ls
```

2. Create feature nucleant:

```bash
loci ide nucleant new N-loci-ide-socket --title "Loci IDE socket" --spec-api loci.ide.socket.v1 --desc "MCP/LSP bridge + finger/nucleant fanout"
```

3. Present to all repos:

```bash
loci ide nucleant present N-loci-ide-socket --repos all --message "please implement against spec api"
```

4. Emit canonical finger plan:

```bash
loci ide finger plan N-loci-ide-socket
```

### Codex Locus Boot (mulsp-first)

When entering `./loci/chatgpt`, bootstrap the work unit as mulsp first, then emit the finger plan.

```bash
loci ide nucleant new N-chatgpt-mulsp-v1 \
  --title "codex-locus mulsp bootstrap" \
  --spec-api docs/MULSP_SPEC.md \
  --desc "spawn mulsp packet, bind codex locus, emit finger.plan for cross-repo pickup"

loci ide nucleant present N-chatgpt-mulsp-v1 --repos mu,loci --message "pickup from ./loci/chatgpt"
loci ide finger plan N-chatgpt-mulsp-v1
```

This allows Codex in `mu` to consume `./loci/chatgpt` outputs through the same nucleant/finger carrier path without direct repo crossover.

Equivalent one-shot boot command:

```bash
loci run -f .
```

5. Emit module componentization skeleton:

```bash
loci ide componentize from-nucleant N-loci-ide-socket --module loci.ide.socket --suffix ide/socket --confidence 0.81
```

6. Apply and generate MoonBit snippet:

```bash
loci ide componentize apply N-loci-ide-socket --module loci.ide.socket --suffix ide/socket --confidence 0.84
```

7. Track convergence:

```bash
loci ide nucleant mark N-loci-ide-socket --repo koan --status in_progress
loci ide nucleant mark N-loci-ide-socket --repo loci --status resolved
loci ide nucleant status N-loci-ide-socket
```

Compliance is shown as resolved/total.

## Socket protocol examples

Start server:

```bash
loci ide serve
```

Loci-native request:

```json
{"id":"1","protocol":"loci","method":"ide.nucleant.status","params":{"id":"N-loci-ide-socket"}}
```

MCP tools list:

```json
{"id":"2","protocol":"mcp","method":"tools/list","params":{}}
```

LSP initialize:

```json
{"id":"3","protocol":"lsp","method":"initialize","params":{}}
```

LSP execute command:

```json
{"id":"4","protocol":"lsp","method":"workspace/executeCommand","params":{"command":"loci.ide.finger.plan","arguments":["N-loci-ide-socket"]}}
```

Loci componentize method:

```json
{"id":"5","protocol":"loci","method":"ide.componentize.from_nucleant","params":{"id":"N-loci-ide-socket","module":"loci.ide.socket","suffix":"ide/socket","confidence":0.81}}
```

Loci componentize apply method:

```json
{"id":"6","protocol":"loci","method":"ide.componentize.apply","params":{"id":"N-loci-ide-socket","module":"loci.ide.socket","suffix":"ide/socket","confidence":0.84}}
```

## Coordination rule

When a repo resolves a nucleant, update status through `loci ide nucleant mark ... --status resolved` and regenerate the finger plan.
