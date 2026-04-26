// loci add — stage files into the CAS-backed staging manifest.

import { LociStore } from "../store.ts"
import { stageFile, scanWorkingTree, getStaging, hashFile, resolveHead, getCommit, getTree } from "../vcs.ts"
import { join } from "path"
import { exists, stat } from "fs/promises"

export async function cmdAdd(store: LociStore, args: string[]): Promise<void> {
  if (args.length === 0) {
    console.error("Usage: loci add <path>... | loci add .")
    process.exit(1)
  }

  let paths = args.filter(a => !a.startsWith("-"))

  // `loci add .` — stage all modified/untracked files
  if (paths.length === 1 && paths[0] === ".") {
    const all = await scanWorkingTree(process.cwd())
    const headHash = await resolveHead(store)
    let treePaths = new Set<string>()

    if (headHash) {
      const commit = await getCommit(store, headHash)
      if (commit) {
        const tree = await getTree(store, commit.treeHash)
        if (tree) treePaths = new Set(tree.entries.map(e => e.path))
      }
    }

    paths = []
    for (const f of all) {
      const fullPath = join(process.cwd(), f.path)
      if (treePaths.has(f.path)) {
        // Check if modified
        const currentHash = await hashFile(fullPath)
        const treeEntry = (await getTree(store, (await getCommit(store, headHash!))!.treeHash))!
          .entries.find(e => e.path === f.path)
        if (treeEntry && treeEntry.hash !== currentHash) paths.push(f.path)
      } else {
        paths.push(f.path)
      }
    }

    if (paths.length === 0) {
      console.log("Nothing to add — working tree matches HEAD.")
      return
    }
  }

  let staged = 0
  for (const p of paths) {
    const fullPath = join(process.cwd(), p)
    if (!await exists(fullPath)) {
      console.error(`  error: pathspec '${p}' did not match any files`)
      continue
    }
    const s = await stat(fullPath)
    if (s.isDirectory()) {
      // Stage all files in directory
      const files = await scanWorkingTree(fullPath, "")
      for (const f of files) {
        await stageFile(store, join(p, f.path))
        staged++
      }
    } else {
      await stageFile(store, p)
      staged++
    }
  }

  console.log(`Staged ${staged} file(s).`)
}
