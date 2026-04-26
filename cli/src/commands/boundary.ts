// loci boundary — boundary walker FSM CLI surface.
// Delegates to the native MoonBit BoundaryWalkerFsm via LociCore.

import { LociStore } from "../store.ts"
import { LociCore } from "../core.ts"
import { renderBoundaryReport } from "../vcs_tui.ts"
import type { BoundaryFinding, BoundaryStatus } from "../types.ts"
import { readFile } from "fs/promises"

export async function cmdBoundary(store: LociStore, args: string[]): Promise<void> {
  const sub = args[0]
  const subArgs = args.slice(1)

  switch (sub) {
    case "walk":
      return boundaryWalk(subArgs)
    case "cross":
      return boundaryCross(subArgs)
    case "status":
      return boundaryStatus(store)
    default:
      console.error("Usage: loci boundary <walk|cross|status>")
      console.error("  walk <file>...     Walk file contents through boundary FSM")
      console.error("  cross --passport <file>   Evaluate a crossing passport")
      console.error("  status             Show current boundary posture")
      process.exit(1)
  }
}

/** Walk files through the boundary FSM, scanning for ghost bytes / bidi / controls. */
async function boundaryWalk(args: string[]): Promise<void> {
  const files = args.filter(a => !a.startsWith("-"))
  if (files.length === 0) {
    console.error("Usage: loci boundary walk <file>...")
    process.exit(1)
  }

  // Pure-TS boundary scanner (mirrors model/boundary_fsm.mbt scan_scalar)
  let totalScalars = 0
  let totalGhostU200b = 0
  let totalGhostU200c = 0
  let totalGhostUfeff = 0
  let totalBidi = 0
  let totalAscii = 0
  const findings: BoundaryFinding[] = []

  for (const file of files) {
    let content: string
    try {
      content = await readFile(file, "utf-8")
    } catch {
      console.error(`  Cannot read: ${file}`)
      continue
    }

    const lines = content.split("\n")
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i]
      totalScalars++
      const scan = scanScalar(line)
      totalGhostU200b += scan.ghostU200b
      totalGhostU200c += scan.ghostU200c
      totalGhostUfeff += scan.ghostUfeff
      totalBidi += scan.bidiControls
      totalAscii += scan.asciiControls

      if (scan.suspicious) {
        findings.push({
          fieldKey: `${file}:${i + 1}`,
          rawValue: line,
          canonicalValue: scan.canonical,
          ghostU200b: scan.ghostU200b,
          ghostU200c: scan.ghostU200c,
          ghostUfeff: scan.ghostUfeff,
          bidiControls: scan.bidiControls,
          asciiControls: scan.asciiControls,
          suspicious: true,
        })
      }
    }
  }

  const ghostTotal = totalGhostU200b + totalGhostU200c + totalGhostUfeff
  const score = ghostTotal * 2 + totalBidi * 8 + totalAscii * 6
  let status: BoundaryStatus = "clean"
  if (totalBidi > 0 || totalAscii > 0) status = "containment"
  else if (ghostTotal > 0) status = "attention"

  let gradient = "quiescent"
  if (score > 0 && score <= 5) gradient = "watch"
  else if (score > 5 && score <= 11) gradient = "pulled"
  else if (score > 11) gradient = "saturated"

  renderBoundaryReport(status, totalScalars, findings, score, gradient)
}

/** Evaluate a crossing passport file. */
async function boundaryCross(args: string[]): Promise<void> {
  const passportFile = flag(args, "--passport")
  if (!passportFile) {
    console.error("Usage: loci boundary cross --passport <file>")
    process.exit(1)
  }

  // Try delegating to native binary
  const core = LociCore.discover()
  const result = await core.run(["daemon", "boundary", "cross", "--passport", passportFile])
  if (result.out) process.stdout.write(result.out)
  if (result.err) process.stderr.write(result.err)
  if (result.code !== 0) process.exit(result.code)
}

async function boundaryStatus(store: LociStore): Promise<void> {
  console.log("Boundary posture: clean (no walk in progress)")
  console.log("  Run 'loci boundary walk <file>...' to scan files")
}

// ── Scanner (mirrors model/boundary_fsm.mbt) ──

interface ScalarScan {
  canonical: string
  ghostU200b: number
  ghostU200c: number
  ghostUfeff: number
  bidiControls: number
  asciiControls: number
  suspicious: boolean
}

function scanScalar(value: string): ScalarScan {
  let canonical = ""
  let ghostU200b = 0, ghostU200c = 0, ghostUfeff = 0
  let bidiControls = 0, asciiControls = 0

  for (const ch of value) {
    const code = ch.codePointAt(0)!
    if (code === 0x200B) { ghostU200b++; continue }
    if (code === 0x200C) { ghostU200c++; continue }
    if (code === 0xFEFF) { ghostUfeff++; continue }
    if (isBidiControl(code)) { bidiControls++; continue }
    if (isAsciiControl(code)) { asciiControls++; continue }
    canonical += ch
  }

  const suspicious = ghostU200b > 0 || ghostU200c > 0 || ghostUfeff > 0 || bidiControls > 0 || asciiControls > 0
  return { canonical: canonical || "none", ghostU200b, ghostU200c, ghostUfeff, bidiControls, asciiControls, suspicious }
}

function isBidiControl(code: number): boolean {
  return [0x202A, 0x202B, 0x202D, 0x202E, 0x202C, 0x2066, 0x2067, 0x2068, 0x2069].includes(code)
}

function isAsciiControl(code: number): boolean {
  return (code >= 0 && code < 32 && code !== 9 && code !== 10 && code !== 13) || code === 127
}

function flag(args: string[], name: string): string | null {
  const i = args.indexOf(name)
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null
}
