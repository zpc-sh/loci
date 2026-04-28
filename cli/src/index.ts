#!/usr/bin/env bun

import { LociStore } from "./store.ts"
import { discoverEngineAdapter } from "./sdk/engine.ts"

const argv = process.argv.slice(2)
const cmd = argv[0]
const rest = argv.slice(1)

const store = LociStore.fromCwd({
  lociRoot: flag(argv, "--loci-root") ?? "loci",
  storePath: flag(argv, "--store") ?? ".loci/store",
})

async function main(): Promise<void> {
  switch (cmd) {
    case "init": {
      const { cmdInit } = await import("./commands/init.ts")
      return cmdInit(store, rest)
    }

    case "loci":
    case "ratio": {
      const { cmdLocusNew, cmdLocusLs } = await import("./commands/locus.ts")
      const sub = rest[0]
      const subRest = rest.slice(1)
      if (sub === "new") return cmdLocusNew(store, subRest)
      if (sub === "ls" || !sub) return cmdLocusLs(store)
      console.error(`Unknown loci subcommand: ${sub}`)
      usage()
      process.exit(1)
    }

    case "genius": {
      const { cmdEnter, cmdSign, cmdTrail, cmdResidue, cmdWhere } = await import("./commands/genius.ts")
      const sub = rest[0]
      const subRest = rest.slice(1)
      if (sub === "enter") return cmdEnter(subRest[0], store, subRest.slice(1))
      if (sub === "sign") return cmdSign(store, subRest)
      if (sub === "trail") return cmdTrail(subRest[0], store, subRest.slice(1))
      if (sub === "residue") return cmdResidue(subRest[0], store)
      if (sub === "where") return cmdWhere(store)
      console.error(`Unknown genius subcommand: ${sub}`)
      usage()
      process.exit(1)
    }

    case "enter": {
      const { cmdEnter } = await import("./commands/genius.ts")
      return cmdEnter(rest[0], store, rest.slice(1))
    }
    case "sign": {
      const { cmdSign } = await import("./commands/genius.ts")
      return cmdSign(store, rest)
    }
    case "trail": {
      const { cmdTrail } = await import("./commands/genius.ts")
      return cmdTrail(rest[0], store, rest.slice(1))
    }
    case "residue": {
      const { cmdResidue } = await import("./commands/genius.ts")
      return cmdResidue(rest[0], store)
    }
    case "where": {
      const { cmdWhere } = await import("./commands/genius.ts")
      return cmdWhere(store)
    }
    case "status": {
      const { cmdStatus } = await import("./commands/status.ts")
      return cmdStatus(store)
    }
    case "ide": {
      const { cmdIde } = await import("./commands/ide.ts")
      return cmdIde(rest)
    }

    case "daemon":
    case "pack":
    case "app": {
      const engine = discoverEngineAdapter(flag(argv, "--engine"))
      const code = await engine.runPrint([cmd, ...rest])
      process.exit(code)
    }

    case "release": {
      const { cmdRelease } = await import("./commands/release.ts")
      return cmdRelease(rest)
    }

    case "run": {
      const { cmdRun } = await import("./commands/run.ts")
      return cmdRun(rest)
    }

    case "spec": {
      const { cmdSpec } = await import("./commands/spec.ts")
      return cmdSpec(rest)
    }

    case "help":
    case "--help":
    case "-h":
      usage()
      return

    default:
      if (cmd) console.error(`Unknown command: ${cmd}\n`)
      usage()
      process.exit(cmd ? 1 : 0)
  }
}

function usage(): void {
  console.log(`
loci — L-OCI content-addressed locus CLI

USAGE
  loci init                               Initialize loci root in current directory
  loci loci new <name> [opts]             Create a new locus
  loci loci ls                            List all loci with last session
  loci genius enter <locus> [--export]    Print enter preamble + session env
  loci genius sign [message]              File a residue for the current session
  loci genius trail <locus> [--depth N]   Show session trail
  loci genius residue <locus>             Show latest residue
  loci genius where                       Overview of all loci + last sessions
  loci ide <subcmd>                       Cross-repo search + codex dropbox messaging
  loci status                             Repository overview
  loci daemon <subcmd>                    Delegate to engine adapter (native|wasm-shim)
  loci release <plan|build>               Build release artifacts and emit manifest
  loci run [-f <dir>]                     Boot mulsp+nucleant+finger plan for a loci dir
  loci spec [--format json|markdown]      Emit the CLI spec (self-describing surface)

  Short aliases: loci enter|sign|trail|residue|where|status

OPTIONS
  --loci-root <path>      Loci directory root (default: loci/)
  --store <path>          OCI blob store path (default: .loci/store/)
  --engine <adapter>      Runtime adapter for daemon/pack/app (native|wasm-shim)
  -f, --from <dir>        Target loci directory for \`run\` (default: .)
  --artifacts-dir <path>  Release artifacts output dir
  --target <all|cli|wasm> Release build target

ENV
  LOCI_ENGINE             Runtime adapter default (native|wasm-shim)
  LOCI_WASM_SHIM_BIN      Binary path for wasm shim adapter
  LOCI_WASM_SHIM_ARGS     Extra argv for wasm shim adapter
  LOCI_GENIUS_ROOT        Path to genius loci source root (daemon delegation)
`.trim())
}

function flag(args: string[], name: string): string | null {
  const i = args.indexOf(name)
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null
}

main().catch(e => {
  console.error(e)
  process.exit(1)
})
