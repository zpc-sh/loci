// loci log — walk commit chain and display history.

import { LociStore } from "../store.ts"
import { resolveHead, walkCommits } from "../vcs.ts"
import { renderLog } from "../vcs_tui.ts"

export async function cmdLog(store: LociStore, args: string[]): Promise<void> {
  const headHash = await resolveHead(store)
  if (!headHash) {
    console.log("No commits yet.")
    return
  }

  const oneline = args.includes("--oneline")
  const limit = parseInt(flag(args, "-n") ?? "50", 10)

  const commits = await walkCommits(store, headHash, limit)
  renderLog(commits, oneline)
}

function flag(args: string[], name: string): string | null {
  const i = args.indexOf(name)
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null
}
