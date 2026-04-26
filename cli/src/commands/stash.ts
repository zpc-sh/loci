// loci stash — save and restore working tree changes.

import { LociStore } from "../store.ts"
import { stashSave, stashList, stashPop, stashDrop } from "../vcs.ts"
import { renderStashList } from "../vcs_tui.ts"

export async function cmdStash(store: LociStore, args: string[]): Promise<void> {
  const sub = args[0]
  const subArgs = args.slice(1)

  switch (sub) {
    case "list":
      renderStashList(await stashList(store))
      return

    case "pop": {
      const entry = await stashPop(store)
      if (entry) {
        console.log(`Applied stash@{${entry.index}}: ${entry.message}`)
      } else {
        console.log("No stashes to pop.")
      }
      return
    }

    case "drop": {
      const idx = subArgs[0] ? parseInt(subArgs[0], 10) : undefined
      if (await stashDrop(store, idx)) {
        console.log("Dropped stash entry.")
      } else {
        console.log("No stash to drop.")
      }
      return
    }

    case "save":
    case undefined: {
      // `loci stash` or `loci stash save "message"`
      const message = (sub === "save" ? subArgs[0] : args[0]) ?? ""
      try {
        const entry = await stashSave(store, message)
        console.log(`Saved working directory to stash@{${entry.index}}: ${entry.message}`)
      } catch (e: any) {
        console.error(e.message)
        process.exit(1)
      }
      return
    }

    default:
      console.error(`Unknown stash subcommand: ${sub}`)
      console.error("Usage: loci stash [save|pop|list|drop]")
      process.exit(1)
  }
}
