// loci branch — branch management. loci switch — switch branches.

import { LociStore } from "../store.ts"
import {
  listBranches, setBranchTip, deleteBranch as deleteBranchOp,
  getHead, setHead, resolveHead, getBranchTip
} from "../vcs.ts"
import { renderBranches } from "../vcs_tui.ts"

export async function cmdBranch(store: LociStore, args: string[]): Promise<void> {
  const deleteFlag = args.includes("-d") || args.includes("--delete")
  const positional = args.filter(a => !a.startsWith("-"))

  if (deleteFlag) {
    const name = positional[0]
    if (!name) { console.error("Usage: loci branch -d <name>"); process.exit(1) }
    const head = await getHead(store)
    if (head.type === "branch" && head.ref === name) {
      console.error(`Cannot delete the currently checked out branch '${name}'`)
      process.exit(1)
    }
    if (await deleteBranchOp(store, name)) {
      console.log(`Deleted branch ${name}.`)
    } else {
      console.error(`Branch '${name}' not found.`)
      process.exit(1)
    }
    return
  }

  if (positional.length > 0) {
    // Create branch
    const name = positional[0]
    const existingTip = await getBranchTip(store, name)
    if (existingTip) {
      console.error(`Branch '${name}' already exists.`)
      process.exit(1)
    }
    const headHash = await resolveHead(store)
    if (!headHash) {
      console.error("Cannot create branch: no commits yet.")
      process.exit(1)
    }
    await setBranchTip(store, name, headHash)
    console.log(`Created branch '${name}' at ${headHash.slice(0, 8)}.`)
    return
  }

  // List branches
  const branches = await listBranches(store)
  const head = await getHead(store)
  if (branches.length === 0) {
    console.log("No branches yet.")
    return
  }
  renderBranches(branches, head)
}

export async function cmdSwitch(store: LociStore, args: string[]): Promise<void> {
  const createFlag = args.includes("-c") || args.includes("--create")
  const positional = args.filter(a => !a.startsWith("-"))
  const name = positional[0]

  if (!name) {
    console.error("Usage: loci switch <branch> | loci switch -c <branch>")
    process.exit(1)
  }

  if (createFlag) {
    const headHash = await resolveHead(store)
    if (!headHash) {
      console.error("Cannot create branch: no commits yet.")
      process.exit(1)
    }
    await setBranchTip(store, name, headHash)
    console.log(`Created and switched to branch '${name}'.`)
  } else {
    const tip = await getBranchTip(store, name)
    if (!tip) {
      console.error(`Branch '${name}' does not exist.`)
      process.exit(1)
    }
  }

  await setHead(store, { type: "branch", ref: name })
  console.log(`Switched to branch '${name}'.`)
}
