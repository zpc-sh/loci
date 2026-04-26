// loci membrane — locus crossing passport and membrane operations.
// Implements the membrane decision table from LOCUS_MEMBRANE_PROFILE.md.

import { LociStore } from "../store.ts"
import type { CrossingPassport, CrossingRecord } from "../types.ts"
import { clack } from "../tui.ts"
import { join } from "path"
import { mkdir, readdir, exists, readFile, writeFile } from "fs/promises"

const MEMBRANE_DIR = ".loci/membranes"

function membranesDir(store: LociStore): string {
  return join(store.lociRoot, MEMBRANE_DIR)
}

function crossingLogPath(store: LociStore): string {
  return join(membranesDir(store), "crossings.json")
}

export async function cmdMembrane(store: LociStore, args: string[]): Promise<void> {
  const sub = args[0]
  const subArgs = args.slice(1)

  switch (sub) {
    case "passport":
      return membranePassport(store, subArgs)
    case "cross":
      return membraneCross(store, subArgs)
    case "log":
      return membraneLog(store)
    default:
      console.error("Usage: loci membrane <passport|cross|log>")
      console.error("  passport create               Interactive passport builder")
      console.error("  cross <src> <dst> --artifact <ref>  Perform crossing")
      console.error("  log                           Show crossing history")
      process.exit(1)
  }
}

async function membranePassport(store: LociStore, args: string[]): Promise<void> {
  if (args[0] !== "create") {
    console.error("Usage: loci membrane passport create")
    process.exit(1)
  }

  clack.intro("Locus Crossing Passport")

  const overlay = await clack.text({ message: "Who: overlay (chatgpt/claude/gemini/human/tool)", placeholder: "claude" })
  if (clack.isCancel(overlay)) { clack.cancel(); process.exit(0) }

  const sourceLocus = await clack.text({ message: "Source locus", placeholder: "loci/chatgpt" })
  if (clack.isCancel(sourceLocus)) { clack.cancel(); process.exit(0) }

  const targetLocus = await clack.text({ message: "Target locus", placeholder: "docs/" })
  if (clack.isCancel(targetLocus)) { clack.cancel(); process.exit(0) }

  const artifactRef = await clack.text({ message: "Artifact reference (path or hash)", placeholder: "loci/chatgpt/LOCUS_MEMBRANE_PROFILE.md" })
  if (clack.isCancel(artifactRef)) { clack.cancel(); process.exit(0) }

  const intent = await clack.select({
    message: "Intent",
    options: [
      { value: "stage", label: "Stage — move to staging area" },
      { value: "canonicalize", label: "Canonicalize — promote to canonical docs" },
      { value: "implement", label: "Implement — create model/runtime code" },
      { value: "audit", label: "Audit — review/observe" },
      { value: "seal", label: "Seal — crystallize with proof" },
      { value: "supersede", label: "Supersede — replace prior material" },
    ],
  })
  if (clack.isCancel(intent)) { clack.cancel(); process.exit(0) }

  const mode = await clack.select({
    message: "Boundary mode",
    options: [
      { value: "observe", label: "Observe — detect/report only" },
      { value: "sanitize", label: "Sanitize — normalize known-safe problems" },
      { value: "strict", label: "Strict — reject non-clean material" },
      { value: "quarantine", label: "Quarantine — isolate into separate lane" },
    ],
  })
  if (clack.isCancel(mode)) { clack.cancel(); process.exit(0) }

  const passportId = new Bun.CryptoHasher("sha256")
    .update(`${overlay}:${sourceLocus}:${targetLocus}:${Date.now()}`)
    .digest("hex").slice(0, 16)

  const passport: CrossingPassport = {
    kind: "loci.crossing.passport",
    version: "v0",
    passportId,
    who: { overlay: overlay as string, family: "model", sessionSurface: "cli" },
    what: { artifactRef: artifactRef as string, artifactType: "profile" },
    why: { intent: intent as string, note: "" },
    where: { sourceLocus: sourceLocus as string, targetLocus: targetLocus as string },
    howFar: { boundaryMode: mode as any, allowedSurfaces: ["docs", "model"], budgetClass: "normal" },
    trace: { contextRef: "", lineageRef: "" },
  }

  await mkdir(membranesDir(store), { recursive: true })
  const passportPath = join(membranesDir(store), `passport-${passportId}.json`)
  await writeFile(passportPath, JSON.stringify(passport, null, 2))

  clack.outro(`Passport saved: ${passportPath}`)
}

async function membraneCross(store: LociStore, args: string[]): Promise<void> {
  const positional = args.filter(a => !a.startsWith("-"))
  const artifactRef = flag(args, "--artifact")
  const [sourceLocus, targetLocus] = positional

  if (!sourceLocus || !targetLocus) {
    console.error("Usage: loci membrane cross <source-locus> <target-locus> --artifact <ref>")
    process.exit(1)
  }

  // Apply membrane decision table
  const mode = flag(args, "--mode") ?? "observe"
  let admitted = true
  let rejection: string | undefined

  // Basic validation
  if (!artifactRef) {
    if (mode === "strict") {
      admitted = false
      rejection = "missing artifact ref in strict mode"
    } else {
      console.log("⚠ Warning: no artifact ref provided — staging only, not canonicalizing.")
    }
  }

  const record: CrossingRecord = {
    passportId: `auto-${Date.now().toString(36)}`,
    sourceLocus,
    targetLocus,
    admitted,
    rejection,
    timestamp: new Date().toISOString(),
    boundaryMode: mode,
  }

  // Append to crossing log
  await mkdir(membranesDir(store), { recursive: true })
  const logPath = crossingLogPath(store)
  const log: CrossingRecord[] = await exists(logPath) ? JSON.parse(await readFile(logPath, "utf-8")) : []
  log.push(record)
  await writeFile(logPath, JSON.stringify(log, null, 2))

  const G = "\x1b[32m", R = "\x1b[31m", X = "\x1b[0m"
  if (admitted) {
    console.log(`${G}✓${X} Crossing admitted: ${sourceLocus} → ${targetLocus} [${mode}]`)
  } else {
    console.log(`${R}✗${X} Crossing denied: ${rejection}`)
  }
}

async function membraneLog(store: LociStore): Promise<void> {
  const logPath = crossingLogPath(store)
  if (!await exists(logPath)) { console.log("No crossings recorded."); return }

  const log: CrossingRecord[] = JSON.parse(await readFile(logPath, "utf-8"))
  if (log.length === 0) { console.log("No crossings recorded."); return }

  const G = "\x1b[32m", R = "\x1b[31m", D = "\x1b[2m", X = "\x1b[0m"
  console.log(`${"TIMESTAMP".padEnd(22)} ${"STATUS".padEnd(10)} ${"MODE".padEnd(12)} SOURCE → TARGET`)
  for (const r of log) {
    const status = r.admitted ? `${G}admitted${X}` : `${R}denied${X}  `
    console.log(`${D}${r.timestamp.slice(0, 19)}${X}   ${status}   ${r.boundaryMode.padEnd(12)} ${r.sourceLocus} → ${r.targetLocus}`)
  }
}

function flag(args: string[], name: string): string | null {
  const i = args.indexOf(name)
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null
}
