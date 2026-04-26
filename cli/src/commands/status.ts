// loci status — enhanced repository overview showing branch, staged, modified, untracked.

import { LociStore } from "../store.ts"
import { exists } from "fs/promises"
import { join } from "path"
import {
  getHead, resolveHead, getStaging, getCommit, getTree,
  scanWorkingTree, hashFile
} from "../vcs.ts"
import { renderVcsStatus } from "../vcs_tui.ts"

export async function cmdStatus(store: LociStore, _args: string[]): Promise<void> {
  const initialized = await exists(join(store.lociRoot, ".loci"))

  if (!initialized) {
    console.log(`Not a loci repository (run: loci init)`)
    return
  }

  const head = await getHead(store)
  const headHash = await resolveHead(store)
  const staged = await getStaging(store)

  // Determine modified and untracked files
  const modified: string[] = []
  const untracked: string[] = []

  if (headHash) {
    const commit = await getCommit(store, headHash)
    if (commit) {
      const tree = await getTree(store, commit.treeHash)
      const trackedPaths = new Set(tree?.entries.map(e => e.path) ?? [])

      // Scan working tree
      const workingFiles = await scanWorkingTree(process.cwd())

      for (const wf of workingFiles) {
        if (trackedPaths.has(wf.path)) {
          // Check if modified
          try {
            const currentHash = await hashFile(join(process.cwd(), wf.path))
            const treeEntry = tree?.entries.find(e => e.path === wf.path)
            if (treeEntry && treeEntry.hash !== currentHash) {
              // Skip if already staged
              if (!staged.some(s => s.path === wf.path)) {
                modified.push(wf.path)
              }
            }
          } catch {
            // File may have been deleted
          }
        } else {
          // Skip if already staged
          if (!staged.some(s => s.path === wf.path)) {
            untracked.push(wf.path)
          }
        }
      }
    }
  } else {
    // No commits yet — everything is untracked
    const workingFiles = await scanWorkingTree(process.cwd())
    for (const wf of workingFiles) {
      if (!staged.some(s => s.path === wf.path)) {
        untracked.push(wf.path)
      }
    }
  }

  renderVcsStatus(head, staged, modified, untracked)

  // Also show locus info if available
  const names = await store.listLoci()
  if (names.length > 0) {
    console.log(`\nLoci: ${names.length} locus/loci configured`)
    for (const name of names) {
      const last = await store.latestResidue(name)
      if (last) {
        console.log(`  ${name}: last session ${last.tier}/${last.sessionShortId} (${last.timestamp.slice(0, 19)})`)
      } else {
        console.log(`  ${name}: no sessions`)
      }
    }
  }
}
