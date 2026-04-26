// loci show — display commit details.

import { LociStore } from "../store.ts"
import { resolveHead, getCommit, getTree, resolveTag } from "../vcs.ts"

const YELLOW = "\x1b[33m"
const GREEN = "\x1b[32m"
const DIM = "\x1b[2m"
const RESET = "\x1b[0m"

export async function cmdShow(store: LociStore, args: string[]): Promise<void> {
  let ref = args[0]

  if (!ref) {
    ref = await resolveHead(store) ?? ""
  }

  if (!ref) {
    console.log("No commits yet.")
    return
  }

  // Try as commit hash first
  let commit = await getCommit(store, ref)

  // Try resolving as tag
  if (!commit) {
    const tag = await resolveTag(store, ref)
    if (tag) {
      commit = await getCommit(store, tag.commitHash)
      if (tag.annotated) {
        console.log(`${YELLOW}tag ${tag.name}${RESET}`)
        if (tag.tagger) console.log(`Tagger: ${tag.tagger}`)
        if (tag.timestamp) console.log(`Date:   ${tag.timestamp}`)
        if (tag.message) console.log(`\n    ${tag.message}\n`)
      }
    }
  }

  if (!commit) {
    console.error(`Object '${ref}' not found.`)
    process.exit(1)
  }

  console.log(`${YELLOW}commit ${commit.hash}${RESET}`)
  if (commit.parentHashes.length > 1) {
    console.log(`Merge: ${commit.parentHashes.map(h => h.slice(0, 8)).join(" ")}`)
  }
  console.log(`Author: ${commit.author}`)
  console.log(`Date:   ${commit.timestamp}`)
  if (commit.envelopeRef) console.log(`${DIM}Envelope: ${commit.envelopeRef}${RESET}`)
  if (commit.boundaryHash) console.log(`${DIM}Boundary: ${commit.boundaryHash}${RESET}`)
  console.log()
  console.log(`    ${commit.message}`)
  console.log()

  // Show tree entries
  const tree = await getTree(store, commit.treeHash)
  if (tree) {
    console.log(`${GREEN}Tree:${RESET} ${tree.hash.slice(0, 8)} (${tree.entries.length} entries)`)
    for (const entry of tree.entries.slice(0, 20)) {
      console.log(`  ${DIM}${entry.hash.slice(0, 8)}${RESET} ${entry.path} (${entry.size}b)`)
    }
    if (tree.entries.length > 20) {
      console.log(`  ${DIM}... and ${tree.entries.length - 20} more${RESET}`)
    }
  }
}
