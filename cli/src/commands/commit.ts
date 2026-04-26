// loci commit — seal staged changes into a content-addressed commit.

import { LociStore } from "../store.ts"
import { createCommit, getStaging, getConfig } from "../vcs.ts"
import { renderCommitSummary } from "../vcs_tui.ts"
import { clack } from "../tui.ts"

export async function cmdCommit(store: LociStore, args: string[]): Promise<void> {
  let message = flag(args, "-m") ?? flag(args, "--message")

  const staging = await getStaging(store)
  if (staging.length === 0) {
    console.error("nothing to commit (use \"loci add\" to stage files)")
    process.exit(1)
  }

  // Interactive message if TTY and no -m
  if (!message && process.stdin.isTTY) {
    clack.intro("loci commit")
    const entered = await clack.text({
      message: "Commit message",
      placeholder: "describe your changes",
    })
    if (clack.isCancel(entered)) { clack.cancel(); process.exit(0) }
    message = entered as string
  }

  if (!message) {
    console.error("Aborting commit due to empty commit message.")
    process.exit(1)
  }

  const config = await getConfig(store)
  const author = config["user.name"]
    ? `${config["user.name"]} <${config["user.email"] ?? ""}>`
    : process.env.USER ?? "loci"

  const commit = await createCommit(store, message, author)
  renderCommitSummary(commit, staging.length)
}

function flag(args: string[], name: string): string | null {
  const i = args.indexOf(name)
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null
}
