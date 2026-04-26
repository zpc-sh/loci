// loci arblock — arblock lifecycle FSM.
// Implements: open → forming → building → aperturing → sealed → superseded

import { LociStore } from "../store.ts"
import type { Arblock, ArblockState, ArblockEntry } from "../types.ts"
import { clack } from "../tui.ts"
import { join } from "path"
import { mkdir, readdir, exists, readFile, writeFile } from "fs/promises"

const ARBLOCK_DIR = ".loci/arblocks"

function arblocksDir(store: LociStore): string {
  return join(store.lociRoot, ARBLOCK_DIR)
}

function arblockPath(store: LociStore, name: string): string {
  return join(arblocksDir(store), `${name}.json`)
}

// ── Valid FSM transitions ──

const VALID_TRANSITIONS: Record<ArblockState, ArblockState[]> = {
  "open": ["forming"],
  "forming": ["building", "sealed"],
  "building": ["aperturing", "sealed"],
  "aperturing": ["sealed"],
  "sealed": ["superseded"],
  "superseded": [],
}

export async function cmdArblock(store: LociStore, args: string[]): Promise<void> {
  const sub = args[0]
  const subArgs = args.slice(1)

  switch (sub) {
    case "new":
      return arblockNew(store, subArgs)
    case "seal":
      return arblockTransition(store, subArgs[0], "sealed")
    case "advance":
      return arblockAdvance(store, subArgs)
    case "status":
      return arblockStatus(store, subArgs[0])
    case "ls":
      return arblockList(store)
    case "supersede":
      return arblockSupersede(store, subArgs)
    default:
      console.error("Usage: loci arblock <new|seal|advance|status|ls|supersede>")
      console.error("  new <name>                Create arblock in 'open' state")
      console.error("  advance <name> <state>    Transition to next state")
      console.error("  seal <name>               Seal arblock (compute material hash)")
      console.error("  status <name>             Show arblock state and entries")
      console.error("  ls                        List all arblocks")
      console.error("  supersede <old> <new>      Create successor arblock")
      process.exit(1)
  }
}

async function arblockNew(store: LociStore, args: string[]): Promise<void> {
  const name = args[0]
  if (!name) { console.error("Usage: loci arblock new <name>"); process.exit(1) }

  await mkdir(arblocksDir(store), { recursive: true })

  if (await exists(arblockPath(store, name))) {
    console.error(`Arblock '${name}' already exists.`)
    process.exit(1)
  }

  let sourceLocus = "unknown"
  const loci = join(store.lociRoot, ".loci")
  if (await exists(loci)) sourceLocus = store.lociRoot

  const arblock: Arblock = {
    name,
    state: "open",
    parentRefs: [],
    sourceLocus,
    createdAt: new Date().toISOString(),
    entries: [],
    sealRefs: [],
  }

  await writeFile(arblockPath(store, name), JSON.stringify(arblock, null, 2))
  console.log(`Created arblock '${name}' [state: open]`)
}

async function arblockTransition(store: LociStore, name: string | undefined, targetState: ArblockState): Promise<void> {
  if (!name) { console.error("Usage: loci arblock seal <name>"); process.exit(1) }

  const arblock = await loadArblock(store, name)
  if (!arblock) { console.error(`Arblock '${name}' not found.`); process.exit(1) }

  const valid = VALID_TRANSITIONS[arblock.state]
  if (!valid.includes(targetState)) {
    console.error(`Cannot transition from '${arblock.state}' to '${targetState}'.`)
    console.error(`Valid transitions: ${valid.join(", ") || "(none — terminal state)"}`)
    process.exit(1)
  }

  arblock.state = targetState

  if (targetState === "sealed") {
    // Compute material hash
    const material = JSON.stringify({
      name: arblock.name,
      entries: arblock.entries,
      parentRefs: arblock.parentRefs,
      sourceLocus: arblock.sourceLocus,
    })
    arblock.materialHash = new Bun.CryptoHasher("sha256").update(material).digest("hex")
    arblock.sealedAt = new Date().toISOString()
  }

  await writeFile(arblockPath(store, name), JSON.stringify(arblock, null, 2))
  console.log(`Arblock '${name}': ${arblock.state}${arblock.materialHash ? ` [hash: ${arblock.materialHash.slice(0, 16)}...]` : ""}`)
}

async function arblockAdvance(store: LociStore, args: string[]): Promise<void> {
  const [name, targetState] = args
  if (!name || !targetState) {
    console.error("Usage: loci arblock advance <name> <state>")
    process.exit(1)
  }
  await arblockTransition(store, name, targetState as ArblockState)
}

async function arblockStatus(store: LociStore, name: string | undefined): Promise<void> {
  if (!name) { console.error("Usage: loci arblock status <name>"); process.exit(1) }
  const arblock = await loadArblock(store, name)
  if (!arblock) { console.error(`Arblock '${name}' not found.`); process.exit(1) }

  const G = "\x1b[32m", Y = "\x1b[33m", D = "\x1b[2m", R = "\x1b[0m"

  console.log(`\n${Y}arblock: ${arblock.name}${R}`)
  console.log(`  state:        ${arblock.state}`)
  console.log(`  source locus: ${arblock.sourceLocus}`)
  console.log(`  created:      ${arblock.createdAt}`)
  if (arblock.sealedAt) console.log(`  sealed:       ${arblock.sealedAt}`)
  if (arblock.materialHash) console.log(`  material:     ${arblock.materialHash}`)
  if (arblock.parentRefs.length > 0) console.log(`  parents:      ${arblock.parentRefs.join(", ")}`)

  if (arblock.entries.length > 0) {
    console.log(`\n  entries (${arblock.entries.length}):`)
    for (const e of arblock.entries) {
      console.log(`    ${D}[${e.state}]${R} ${e.family}/${e.name}${e.holeId ? ` ← ${e.holeId}` : ""}`)
    }
  }

  const valid = VALID_TRANSITIONS[arblock.state]
  if (valid.length > 0) {
    console.log(`\n  ${G}next states:${R} ${valid.join(", ")}`)
  }
  console.log()
}

async function arblockList(store: LociStore): Promise<void> {
  const dir = arblocksDir(store)
  if (!await exists(dir)) { console.log("No arblocks."); return }

  const files = (await readdir(dir)).filter(f => f.endsWith(".json")).sort()
  if (files.length === 0) { console.log("No arblocks."); return }

  const Y = "\x1b[33m", D = "\x1b[2m", R = "\x1b[0m"
  console.log(`${"NAME".padEnd(24)} ${"STATE".padEnd(14)} ${"CREATED".padEnd(22)} ENTRIES`)
  for (const f of files) {
    const arblock: Arblock = JSON.parse(await readFile(join(dir, f), "utf-8"))
    console.log(
      `${Y}${arblock.name.padEnd(24)}${R} ${arblock.state.padEnd(14)} ${D}${arblock.createdAt.slice(0, 19).padEnd(22)}${R} ${arblock.entries.length}`
    )
  }
}

async function arblockSupersede(store: LociStore, args: string[]): Promise<void> {
  const [oldName, newName] = args
  if (!oldName || !newName) {
    console.error("Usage: loci arblock supersede <old-name> <new-name>")
    process.exit(1)
  }

  const old = await loadArblock(store, oldName)
  if (!old) { console.error(`Arblock '${oldName}' not found.`); process.exit(1) }
  if (old.state !== "sealed") {
    console.error(`Cannot supersede: '${oldName}' is not sealed (state: ${old.state}).`)
    process.exit(1)
  }

  // Mark old as superseded
  old.state = "superseded"
  await writeFile(arblockPath(store, oldName), JSON.stringify(old, null, 2))

  // Create successor
  const successor: Arblock = {
    name: newName,
    state: "open",
    parentRefs: [oldName],
    sourceLocus: old.sourceLocus,
    createdAt: new Date().toISOString(),
    entries: [],
    sealRefs: [],
  }
  await writeFile(arblockPath(store, newName), JSON.stringify(successor, null, 2))
  console.log(`Superseded '${oldName}' → new arblock '${newName}' [state: open, parent: ${oldName}]`)
}

async function loadArblock(store: LociStore, name: string): Promise<Arblock | null> {
  const p = arblockPath(store, name)
  if (!await exists(p)) return null
  return JSON.parse(await readFile(p, "utf-8"))
}
