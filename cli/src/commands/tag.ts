// loci tag — tag management.

import { LociStore } from "../store.ts"
import { createTag as createTagOp, listTags, deleteTag as deleteTagOp, resolveHead, getConfig } from "../vcs.ts"
import { renderTags } from "../vcs_tui.ts"
import type { Tag } from "../types.ts"

export async function cmdTag(store: LociStore, args: string[]): Promise<void> {
  const listFlag = args.includes("-l") || args.includes("--list")
  const deleteFlag = args.includes("-d") || args.includes("--delete")
  const annotatedFlag = args.includes("-a") || args.includes("--annotate")
  const message = flag(args, "-m") ?? flag(args, "--message")
  const positional = args.filter(a => !a.startsWith("-") && a !== flag(args, "-m") && a !== flag(args, "--message"))

  if (listFlag || positional.length === 0) {
    const tags = await listTags(store)
    if (tags.length === 0) {
      console.log("No tags yet.")
    } else {
      renderTags(tags)
    }
    return
  }

  if (deleteFlag) {
    const name = positional[0]
    if (!name) { console.error("Usage: loci tag -d <name>"); process.exit(1) }
    if (await deleteTagOp(store, name)) {
      console.log(`Deleted tag '${name}'.`)
    } else {
      console.error(`Tag '${name}' not found.`)
      process.exit(1)
    }
    return
  }

  // Create tag
  const name = positional[0]
  const headHash = await resolveHead(store)
  if (!headHash) {
    console.error("Cannot create tag: no commits yet.")
    process.exit(1)
  }

  const config = await getConfig(store)
  const tagger = config["user.name"]
    ? `${config["user.name"]} <${config["user.email"] ?? ""}>`
    : process.env.USER ?? "loci"

  const tag: Tag = {
    name,
    commitHash: headHash,
    annotated: annotatedFlag || !!message,
    message: message ?? undefined,
    tagger: (annotatedFlag || !!message) ? tagger : undefined,
    timestamp: (annotatedFlag || !!message) ? new Date().toISOString() : undefined,
  }

  await createTagOp(store, tag)
  console.log(`Created tag '${name}' at ${headHash.slice(0, 8)}.`)
}

function flag(args: string[], name: string): string | null {
  const i = args.indexOf(name)
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null
}
