# Loci IDE Socket Dogfood — Codex↔Codex

Status: active dogfood playbook

Scope: coordinate in `./loci/chatgpt` while keeping repo boundaries intact.

## Goal

Use `loci ide` as the communication socket and nucleant carrier so codexes do not enter each other's repos.

## First-class primitives

- repo registry: `loci ide repo add|ls`
- cross-repo search: `loci ide search`
- codex dropbox: `loci ide ask`, `loci ide inbox`
- nucleant workflow: `loci ide nucleant new|present|mark|status`
- finger plan: `loci ide finger plan <nucleant-id>`
- socket bridge: `loci ide serve` (JSON-RPC over stdio, protocol=`loci|mcp|lsp`)

## Dogfood flow

1. Register peer repos:

```bash
loci ide repo add koan ../koan
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

5. Track convergence:

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

## Coordination rule

When a repo resolves a nucleant, update status through `loci ide nucleant mark ... --status resolved` and regenerate the finger plan.
