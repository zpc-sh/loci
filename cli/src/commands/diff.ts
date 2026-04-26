// loci diff — show differences between working tree, staging, and commits.

import { LociStore } from "../store.ts"
import { getStaging, resolveHead, getCommit, getTree, hashFile, scanWorkingTree, diffLines } from "../vcs.ts"
import { renderDiff } from "../vcs_tui.ts"
import type { FileDiff } from "../types.ts"
import { join } from "path"
import { readFile } from "fs/promises"

export async function cmdDiff(store: LociStore, args: string[]): Promise<void> {
  const staged = args.includes("--staged") || args.includes("--cached")

  if (staged) {
    await diffStaged(store)
  } else {
    await diffWorking(store)
  }
}

/** Diff working tree against HEAD (or staging if staged files exist). */
async function diffWorking(store: LociStore): Promise<void> {
  const headHash = await resolveHead(store)
  if (!headHash) {
    console.log("No commits to diff against.")
    return
  }
  const commit = await getCommit(store, headHash)
  if (!commit) return

  const tree = await getTree(store, commit.treeHash)
  if (!tree) return

  const diffs: FileDiff[] = []
  const cwd = process.cwd()

  for (const entry of tree.entries) {
    const fullPath = join(cwd, entry.path)
    try {
      const currentHash = await hashFile(fullPath)
      if (currentHash !== entry.hash) {
        const oldBlob = await store.getBlob(entry.hash)
        const oldText = oldBlob ? new TextDecoder().decode(oldBlob) : ""
        const newText = await readFile(fullPath, "utf-8")
        diffs.push(diffLines(oldText, newText, entry.path))
      }
    } catch {
      // File deleted in working tree
      const oldBlob = await store.getBlob(entry.hash)
      const oldText = oldBlob ? new TextDecoder().decode(oldBlob) : ""
      diffs.push(diffLines(oldText, "", entry.path))
    }
  }

  renderDiff(diffs)
}

/** Diff staged changes against HEAD. */
async function diffStaged(store: LociStore): Promise<void> {
  const staging = await getStaging(store)
  if (staging.length === 0) {
    console.log("No staged changes.")
    return
  }

  const headHash = await resolveHead(store)
  const diffs: FileDiff[] = []

  for (const s of staging) {
    let oldText = ""
    if (headHash) {
      const commit = await getCommit(store, headHash)
      if (commit) {
        const tree = await getTree(store, commit.treeHash)
        const entry = tree?.entries.find(e => e.path === s.path)
        if (entry) {
          const blob = await store.getBlob(entry.hash)
          if (blob) oldText = new TextDecoder().decode(blob)
        }
      }
    }

    if (s.action === "delete") {
      diffs.push(diffLines(oldText, "", s.path))
    } else {
      const blob = await store.getBlob(s.blobHash)
      const newText = blob ? new TextDecoder().decode(blob) : ""
      diffs.push(diffLines(oldText, newText, s.path))
    }
  }

  renderDiff(diffs)
}
