#!/usr/bin/env bun
// loci — L-OCI content-addressed locus CLI/TUI
//
// Architecture:
//   LociStore (store.ts)   — host-side OCI blob/tag + residue persistence (the "last leg")
//   LociCore  (core.ts)    — delegates tree/bloom/daemon ops to native merkin binary
//   vcs.ts                 — VCS ops: staging, commits, branches, tags, diffs, tree tracking
//   commands/ (commands/)  — one concern per file; each command imports only what it needs
//   tui.ts                 — @clack/prompts + terminal renderers matching locus/locus.mbt output
//   vcs_tui.ts             — VCS-specific renderers: log, diff, branches, tags
//
// Adding a new command: add a file to src/commands/, export an async function, wire it below.

import { LociStore } from "./store.ts"
import { LociCore } from "./core.ts"
import { initVcs } from "./vcs.ts"

// Commands: locus management
import { cmdInit } from "./commands/init.ts"
import { cmdLocusNew, cmdLocusLs } from "./commands/locus.ts"
import { cmdEnter, cmdSign, cmdTrail, cmdResidue, cmdWhere } from "./commands/genius.ts"
import { cmdStatus } from "./commands/status.ts"

// Commands: VCS (git-parity)
import { cmdAdd } from "./commands/add.ts"
import { cmdCommit } from "./commands/commit.ts"
import { cmdLog } from "./commands/log.ts"
import { cmdDiff } from "./commands/diff.ts"
import { cmdBranch, cmdSwitch } from "./commands/branch.ts"
import { cmdMerge } from "./commands/merge.ts"
import { cmdTag } from "./commands/tag.ts"
import { cmdStash } from "./commands/stash.ts"
import { cmdConfig } from "./commands/config.ts"
import { cmdRemote, cmdFetch, cmdPush, cmdPull, cmdClone } from "./commands/remote.ts"
import { cmdShow } from "./commands/show.ts"

// Commands: FSM primitives
import { cmdBoundary } from "./commands/boundary.ts"
import { cmdArblock } from "./commands/arblock.ts"
import { cmdMembrane } from "./commands/membrane.ts"

const argv = process.argv.slice(2)
const cmd = argv[0]
const rest = argv.slice(1)

const store = LociStore.fromCwd({
  lociRoot: flag(argv, "--loci-root") ?? "loci",
  storePath: flag(argv, "--store") ?? ".loci/store",
})
const core = LociCore.discover()

async function main(): Promise<void> {
  switch (cmd) {
    // --- Repository lifecycle ---
    case "init":
      await cmdInit(store, rest)
      await initVcs(store)
      return

    case "clone":     return cmdClone(store, rest)

    // --- VCS porcelain ---
    case "add":       return cmdAdd(store, rest)
    case "commit":    return cmdCommit(store, rest)
    case "log":       return cmdLog(store, rest)
    case "diff":      return cmdDiff(store, rest)
    case "branch":    return cmdBranch(store, rest)
    case "switch":
    case "checkout":  return cmdSwitch(store, rest)
    case "merge":     return cmdMerge(store, rest)
    case "tag":       return cmdTag(store, rest)
    case "stash":     return cmdStash(store, rest)
    case "show":      return cmdShow(store, rest)
    case "config":    return cmdConfig(store, rest)
    case "status":    return cmdStatus(store, rest)

    // --- Remote / network ---
    case "remote":    return cmdRemote(store, rest)
    case "fetch":     return cmdFetch(store, rest)
    case "push":      return cmdPush(store, rest)
    case "pull":      return cmdPull(store, rest)

    // --- FSM primitives ---
    case "boundary":  return cmdBoundary(store, rest)
    case "arblock":   return cmdArblock(store, rest)
    case "membrane":  return cmdMembrane(store, rest)

    // --- Locus management ---
    case "loci":
    case "ratio": {
      const sub = rest[0]
      const subRest = rest.slice(1)
      if (sub === "new") return cmdLocusNew(store, subRest)
      if (sub === "ls" || !sub) return cmdLocusLs(store)
      console.error(`Unknown loci subcommand: ${sub}`); usage(); process.exit(1)
    }

    // --- Genius (session management) ---
    case "genius": {
      const sub = rest[0]
      const subRest = rest.slice(1)
      if (sub === "enter") return cmdEnter(subRest[0], store, subRest.slice(1))
      if (sub === "sign") return cmdSign(store, subRest)
      if (sub === "trail") return cmdTrail(subRest[0], store, subRest.slice(1))
      if (sub === "residue") return cmdResidue(subRest[0], store)
      if (sub === "where") return cmdWhere(store)
      console.error(`Unknown genius subcommand: ${sub}`); usage(); process.exit(1)
    }

    // Short aliases — drop the group token so you can type `loci enter foo`
    case "enter":   return cmdEnter(rest[0], store, rest.slice(1))
    case "sign":    return cmdSign(store, rest)
    case "trail":   return cmdTrail(rest[0], store, rest.slice(1))
    case "residue": return cmdResidue(rest[0], store)
    case "where":   return cmdWhere(store)

    // Delegate to native genius binary (tree / bloom / OCI daemon ops)
    case "daemon":
    case "pack":
    case "app": {
      const code = await core.runPrint([cmd, ...rest])
      process.exit(code)
    }

    case "help":
    case "--help":
    case "-h":
      usage(); return

    default:
      if (cmd) console.error(`Unknown command: ${cmd}\n`)
      usage()
      process.exit(cmd ? 1 : 0)
  }
}

function usage(): void {
  console.log(`
loci — L-OCI content-addressed locus CLI

USAGE — VCS (git-parity)
  loci init                               Initialize loci repository
  loci clone <url>                        Clone from OCI registry
  loci add <path>...                      Stage files for commit
  loci commit -m "message"                Commit staged changes
  loci log [--oneline] [-n N]             Show commit history
  loci diff [--staged]                    Show working tree / staged diffs
  loci show [<ref>]                       Show commit or tag details
  loci status                             Repository status overview
  loci branch [<name>] [-d <name>]        List / create / delete branches
  loci switch <branch> [-c]               Switch branches (optionally create)
  loci merge <branch>                     Merge branch into current
  loci tag [<name>] [-a -m "msg"] [-d]    Create / list / delete tags
  loci stash [save|pop|list|drop]         Stash working tree changes
  loci config [<key> [<value>]] [--list]  Get/set/list config
  loci remote [add|rm|ls] <name> <url>    Manage remotes
  loci fetch|push|pull [<remote>]         Remote sync operations

USAGE — Locus management
  loci loci new <name> [opts]             Create a new locus
  loci loci ls                            List all loci with last session

USAGE — Genius (session management)
  loci genius enter <locus> [--export]    Print enter preamble + session env
  loci genius sign [message]              File a residue for the current session
  loci genius trail <locus> [--depth N]   Show session trail
  loci genius residue <locus>             Show latest residue
  loci genius where                       Overview of all loci + last sessions

USAGE — FSM primitives
  loci boundary walk <file>...            Scan files for ghost bytes / bidi controls
  loci boundary cross --passport <file>   Evaluate a crossing passport
  loci arblock new|seal|status|ls|advance Arblock lifecycle management
  loci membrane passport create           Create a crossing passport
  loci membrane cross <src> <dst>         Perform membrane crossing
  loci membrane log                       Show crossing history

  Short aliases: loci enter|sign|trail|residue|where|status

OPTIONS
  --loci-root <path>  Loci directory root       (default: loci/)
  --store <path>      OCI blob store path        (default: .loci/store/)
  --locus <name>      Override current locus     (or set LOCI_LOCUS)
  --tier <tier>       Claude tier for signing    (default: sonnet)
  --depth <n>         Trail depth limit          (default: 10)
  --export            Print eval-able export lines for enter

ENV
  LOCI_LOCUS          Current locus name (set via: eval $(loci enter <name> --export))
  LOCI_TIER           Claude tier for this session
  LOCI_SESSION        tier/shortId for signing
  LOCI_GENIUS_ROOT    Path to genius loci source root (for daemon delegation)
`.trim())
}

function flag(args: string[], name: string): string | null {
  const i = args.indexOf(name)
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null
}

main().catch(e => { console.error(e); process.exit(1) })
