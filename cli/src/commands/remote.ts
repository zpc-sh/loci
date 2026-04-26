// loci remote — remote registry management + fetch/push/pull/clone stubs.

import { LociStore } from "../store.ts"
import { getRemotes, addRemote, removeRemote } from "../vcs.ts"
import type { RemoteConfig } from "../types.ts"

export async function cmdRemote(store: LociStore, args: string[]): Promise<void> {
  const sub = args[0]
  const subArgs = args.slice(1)

  switch (sub) {
    case "add": {
      const [name, url] = subArgs
      if (!name || !url) { console.error("Usage: loci remote add <name> <url>"); process.exit(1) }
      try {
        await addRemote(store, { name, url })
        console.log(`Added remote '${name}' → ${url}`)
      } catch (e: any) {
        console.error(e.message)
        process.exit(1)
      }
      return
    }

    case "rm":
    case "remove": {
      const name = subArgs[0]
      if (!name) { console.error("Usage: loci remote rm <name>"); process.exit(1) }
      if (await removeRemote(store, name)) {
        console.log(`Removed remote '${name}'.`)
      } else {
        console.error(`Remote '${name}' not found.`)
        process.exit(1)
      }
      return
    }

    case "ls":
    case undefined: {
      const remotes = await getRemotes(store)
      if (remotes.length === 0) {
        console.log("No remotes configured.")
      } else {
        for (const r of remotes) {
          console.log(`${r.name}\t${r.url}${r.pushUrl ? ` (push: ${r.pushUrl})` : ""}`)
        }
      }
      return
    }

    default:
      console.error(`Unknown remote subcommand: ${sub}`)
      process.exit(1)
  }
}

export async function cmdFetch(_store: LociStore, args: string[]): Promise<void> {
  const remote = args[0] ?? "origin"
  console.log(`fetch: would fetch from remote '${remote}' (OCI registry transport not yet wired)`)
  console.log("  → future: pull manifests from OCI registry, update refs/remotes/")
}

export async function cmdPush(_store: LociStore, args: string[]): Promise<void> {
  const remote = args[0] ?? "origin"
  console.log(`push: would push to remote '${remote}' (OCI registry transport not yet wired)`)
  console.log("  → future: push commit tree as OCI manifests + blobs")
}

export async function cmdPull(_store: LociStore, args: string[]): Promise<void> {
  const remote = args[0] ?? "origin"
  console.log(`pull: would fetch + merge from remote '${remote}' (OCI registry transport not yet wired)`)
}

export async function cmdClone(_store: LociStore, args: string[]): Promise<void> {
  const url = args[0]
  if (!url) { console.error("Usage: loci clone <url>"); process.exit(1) }
  console.log(`clone: would clone from '${url}' (OCI registry transport not yet wired)`)
  console.log("  → future: init + fetch all refs + checkout default branch")
}
