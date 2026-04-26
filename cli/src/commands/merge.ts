// loci merge — three-way merge between branches.

import { LociStore } from "../store.ts"
import {
  getHead, resolveHead, getBranchTip, getCommit, getTree,
  putCommit, setBranchTip, buildTreeFromStaging, setStaging, putTree
} from "../vcs.ts"
import type { Commit, TreeEntry, StagingEntry, TreeManifest } from "../types.ts"

export async function cmdMerge(store: LociStore, args: string[]): Promise<void> {
  const targetBranch = args[0]
  if (!targetBranch) {
    console.error("Usage: loci merge <branch>")
    process.exit(1)
  }

  const head = await getHead(store)
  if (head.type !== "branch") {
    console.error("Cannot merge in detached HEAD state.")
    process.exit(1)
  }

  const currentHash = await resolveHead(store)
  const targetHash = await getBranchTip(store, targetBranch)

  if (!currentHash) {
    console.error("No commits on current branch.")
    process.exit(1)
  }
  if (!targetHash) {
    console.error(`Branch '${targetBranch}' not found.`)
    process.exit(1)
  }
  if (currentHash === targetHash) {
    console.log("Already up to date.")
    return
  }

  // Check for fast-forward: if current is ancestor of target
  const targetCommit = await getCommit(store, targetHash)
  if (!targetCommit) { console.error("Cannot read target commit."); process.exit(1) }

  if (await isAncestor(store, currentHash, targetHash)) {
    // Fast-forward
    await setBranchTip(store, head.ref, targetHash)
    console.log(`Fast-forward merge: ${head.ref} → ${targetHash.slice(0, 8)}`)
    return
  }

  // Real merge: combine trees
  const currentCommit = await getCommit(store, currentHash)
  if (!currentCommit) { console.error("Cannot read current commit."); process.exit(1) }

  const currentTree = await getTree(store, currentCommit.treeHash)
  const targetTree = await getTree(store, targetCommit.treeHash)
  if (!currentTree || !targetTree) { console.error("Cannot read trees."); process.exit(1) }

  // Simple merge: union of entries, target wins on conflict
  const mergedMap = new Map<string, TreeEntry>()
  for (const e of currentTree.entries) mergedMap.set(e.path, e)
  for (const e of targetTree.entries) mergedMap.set(e.path, e) // target wins

  const mergedEntries = Array.from(mergedMap.values()).sort((a, b) => a.path.localeCompare(b.path))
  const mergedManifest: TreeManifest = { hash: "", entries: mergedEntries }
  const treeHash = await putTree(store, mergedManifest)

  const mergeCommit: Commit = {
    hash: "",
    parentHashes: [currentHash, targetHash],
    treeHash,
    author: currentCommit.author,
    timestamp: new Date().toISOString(),
    message: `Merge branch '${targetBranch}' into ${head.ref}`,
  }

  const hash = await putCommit(store, mergeCommit)
  await setBranchTip(store, head.ref, hash)
  console.log(`Merged '${targetBranch}' into '${head.ref}' → ${hash.slice(0, 8)}`)
}

/** Check if potentialAncestor is an ancestor of descendant. */
async function isAncestor(store: LociStore, potentialAncestor: string, descendant: string): Promise<boolean> {
  let current: string | null = descendant
  const seen = new Set<string>()
  while (current && !seen.has(current)) {
    if (current === potentialAncestor) return true
    seen.add(current)
    const commit = await getCommit(store, current)
    if (!commit) break
    current = commit.parentHashes[0] ?? null
  }
  return false
}
