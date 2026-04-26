// VCS TUI renderers: log, diff, branches, tags, commit summaries.
// Complements tui.ts with git-parity display primitives.

import type { Commit, Branch, Tag, FileDiff, StagingEntry, HeadState, StashEntry, BoundaryFinding } from "./types.ts"

const DIM = "\x1b[2m"
const BOLD = "\x1b[1m"
const RESET = "\x1b[0m"
const YELLOW = "\x1b[33m"
const GREEN = "\x1b[32m"
const RED = "\x1b[31m"
const CYAN = "\x1b[36m"
const MAGENTA = "\x1b[35m"

// ── Log ──

export function renderLog(commits: Commit[], oneline: boolean = false): void {
  for (const c of commits) {
    if (oneline) {
      console.log(`${YELLOW}${c.hash.slice(0, 8)}${RESET} ${c.message}`)
    } else {
      console.log(`${YELLOW}commit ${c.hash}${RESET}`)
      if (c.parentHashes.length > 1) {
        console.log(`Merge: ${c.parentHashes.map(h => h.slice(0, 8)).join(" ")}`)
      }
      console.log(`Author: ${c.author}`)
      console.log(`Date:   ${c.timestamp}`)
      if (c.boundaryHash) console.log(`${DIM}Boundary: ${c.boundaryHash}${RESET}`)
      console.log()
      console.log(`    ${c.message}`)
      console.log()
    }
  }
}

// ── Diff ──

export function renderDiff(diffs: FileDiff[]): void {
  if (diffs.length === 0) {
    console.log("No differences.")
    return
  }
  for (const d of diffs) {
    console.log(`${BOLD}diff --loci a/${d.path} b/${d.path}${RESET}`)
    if (d.status === "added") console.log(`${GREEN}new file${RESET}`)
    if (d.status === "deleted") console.log(`${RED}deleted file${RESET}`)
    if (d.status === "renamed") console.log(`${CYAN}renamed: ${d.oldPath} → ${d.path}${RESET}`)
    if (d.binary) { console.log("Binary file differs"); continue }

    for (const hunk of d.hunks) {
      console.log(`${CYAN}@@ -${hunk.oldStart},${hunk.oldCount} +${hunk.newStart},${hunk.newCount} @@${RESET}`)
      for (const line of hunk.lines) {
        if (line.type === "add") console.log(`${GREEN}+${line.content}${RESET}`)
        else if (line.type === "remove") console.log(`${RED}-${line.content}${RESET}`)
        else console.log(` ${line.content}`)
      }
    }
    console.log()
  }
}

// ── Branches ──

export function renderBranches(branches: Branch[], head: HeadState): void {
  for (const b of branches) {
    const current = head.type === "branch" && head.ref === b.name
    const prefix = current ? `${GREEN}* ` : "  "
    const suffix = current ? RESET : ""
    const hash = DIM + b.commitHash.slice(0, 8) + RESET
    console.log(`${prefix}${b.name}${suffix} ${hash}`)
  }
}

// ── Tags ──

export function renderTags(tags: Tag[]): void {
  for (const t of tags) {
    if (t.annotated && t.message) {
      console.log(`${YELLOW}${t.name}${RESET} ${DIM}${t.commitHash.slice(0, 8)}${RESET} — ${t.message}`)
    } else {
      console.log(`${YELLOW}${t.name}${RESET} ${DIM}${t.commitHash.slice(0, 8)}${RESET}`)
    }
  }
}

// ── Commit summary ──

export function renderCommitSummary(commit: Commit, filesChanged: number): void {
  console.log(`${YELLOW}[${commit.hash.slice(0, 8)}]${RESET} ${commit.message}`)
  console.log(` ${filesChanged} file(s) changed`)
}

// ── Status ──

export function renderVcsStatus(
  head: HeadState,
  staged: StagingEntry[],
  modified: string[],
  untracked: string[],
): void {
  if (head.type === "branch") {
    console.log(`On branch ${GREEN}${head.ref}${RESET}`)
  } else {
    console.log(`${RED}HEAD detached at ${head.ref.slice(0, 8)}${RESET}`)
  }
  console.log()

  if (staged.length > 0) {
    console.log(`Changes to be committed:`)
    console.log(`  (use "loci restore --staged <file>..." to unstage)`)
    console.log()
    for (const s of staged) {
      const label = s.action === "delete" ? "deleted" : s.action === "modify" ? "modified" : "new file"
      console.log(`\t${GREEN}${label}:   ${s.path}${RESET}`)
    }
    console.log()
  }

  if (modified.length > 0) {
    console.log(`Changes not staged for commit:`)
    console.log(`  (use "loci add <file>..." to update what will be committed)`)
    console.log()
    for (const m of modified) {
      console.log(`\t${RED}modified:   ${m}${RESET}`)
    }
    console.log()
  }

  if (untracked.length > 0) {
    console.log(`Untracked files:`)
    console.log(`  (use "loci add <file>..." to include in what will be committed)`)
    console.log()
    for (const u of untracked) {
      console.log(`\t${RED}${u}${RESET}`)
    }
    console.log()
  }

  if (staged.length === 0 && modified.length === 0 && untracked.length === 0) {
    console.log(`nothing to commit, working tree clean`)
  }
}

// ── Stash ──

export function renderStashList(stashes: StashEntry[]): void {
  if (stashes.length === 0) { console.log("No stashes."); return }
  for (const s of stashes) {
    console.log(`${MAGENTA}stash@{${s.index}}${RESET}: ${s.message} ${DIM}(${s.timestamp.slice(0, 19)})${RESET}`)
  }
}

// ── Boundary ──

export function renderBoundaryReport(
  status: string,
  walkedScalars: number,
  findings: BoundaryFinding[],
  attentionScore: number,
  attentionGradient: string,
): void {
  console.log(`\n─── Boundary Walk Report ───`)
  console.log(`Status:              ${status === "clean" ? GREEN : status === "attention" ? YELLOW : RED}${status}${RESET}`)
  console.log(`Walked scalars:      ${walkedScalars}`)
  console.log(`Attention score:     ${attentionScore}`)
  console.log(`Attention gradient:  ${attentionGradient}`)

  if (findings.length > 0) {
    console.log(`\nFindings (${findings.length}):`)
    for (const f of findings) {
      console.log(`  ${RED}⚠${RESET} ${f.fieldKey}`)
      console.log(`    canonical: ${f.canonicalValue}`)
      if (f.ghostU200b > 0) console.log(`    ghost U+200B: ${f.ghostU200b}`)
      if (f.ghostU200c > 0) console.log(`    ghost U+200C: ${f.ghostU200c}`)
      if (f.ghostUfeff > 0) console.log(`    ghost U+FEFF: ${f.ghostUfeff}`)
      if (f.bidiControls > 0) console.log(`    bidi controls: ${f.bidiControls}`)
      if (f.asciiControls > 0) console.log(`    ascii controls: ${f.asciiControls}`)
    }
  }
  console.log(`────────────────────────────\n`)
}
