// VCS operations: staging, commits, branches, tags, diffs, working tree tracking.
// Extends LociStore with git-parity semantics backed by the CAS blob store.

import { join } from "path"
import { mkdir, readdir, exists, readFile, writeFile, stat, unlink } from "fs/promises"
import { LociStore } from "./store.ts"
import type {
  Commit, TreeEntry, TreeManifest, Branch, Tag,
  StagingEntry, HeadState, StashEntry, FileDiff,
  DiffHunk, DiffLine, RemoteConfig
} from "./types.ts"

// ── Paths ──

function lociDir(store: LociStore): string { return join(store.lociRoot, ".loci") }
function headsDir(store: LociStore): string { return join(lociDir(store), "refs", "heads") }
function tagsDir(store: LociStore): string { return join(lociDir(store), "refs", "tags") }
function stagingPath(store: LociStore): string { return join(lociDir(store), "staging.json") }
function headPath(store: LociStore): string { return join(lociDir(store), "HEAD") }
function commitsDir(store: LociStore): string { return join(lociDir(store), "objects", "commits") }
function treesDir(store: LociStore): string { return join(lociDir(store), "objects", "trees") }
function stashDir(store: LociStore): string { return join(lociDir(store), "stash") }
function configPath(store: LociStore): string { return join(lociDir(store), "config.json") }
function remotesPath(store: LociStore): string { return join(lociDir(store), "remotes.json") }

// ── Init VCS structure ──

export async function initVcs(store: LociStore): Promise<void> {
  for (const d of [headsDir(store), tagsDir(store), commitsDir(store), treesDir(store), stashDir(store)]) {
    await mkdir(d, { recursive: true })
  }
  if (!await exists(headPath(store))) {
    await writeFile(headPath(store), "ref: refs/heads/main\n")
  }
}

// ── HEAD ──

export async function getHead(store: LociStore): Promise<HeadState> {
  if (!await exists(headPath(store))) return { type: "branch", ref: "main" }
  const raw = (await readFile(headPath(store), "utf-8")).trim()
  if (raw.startsWith("ref: refs/heads/")) {
    return { type: "branch", ref: raw.slice("ref: refs/heads/".length) }
  }
  return { type: "detached", ref: raw }
}

export async function setHead(store: LociStore, state: HeadState): Promise<void> {
  const content = state.type === "branch" ? `ref: refs/heads/${state.ref}\n` : `${state.ref}\n`
  await writeFile(headPath(store), content)
}

export async function resolveHead(store: LociStore): Promise<string | null> {
  const head = await getHead(store)
  if (head.type === "detached") return head.ref
  return getBranchTip(store, head.ref)
}

// ── Branches ──

export async function getBranchTip(store: LociStore, name: string): Promise<string | null> {
  const p = join(headsDir(store), name)
  return await exists(p) ? (await readFile(p, "utf-8")).trim() : null
}

export async function setBranchTip(store: LociStore, name: string, hash: string): Promise<void> {
  await mkdir(headsDir(store), { recursive: true })
  await writeFile(join(headsDir(store), name), hash + "\n")
}

export async function listBranches(store: LociStore): Promise<Branch[]> {
  const dir = headsDir(store)
  if (!await exists(dir)) return []
  const files = await readdir(dir)
  const branches: Branch[] = []
  for (const f of files) {
    const hash = (await readFile(join(dir, f), "utf-8")).trim()
    branches.push({ name: f, commitHash: hash })
  }
  return branches.sort((a, b) => a.name.localeCompare(b.name))
}

export async function deleteBranch(store: LociStore, name: string): Promise<boolean> {
  const p = join(headsDir(store), name)
  if (!await exists(p)) return false
  await unlink(p)
  return true
}

// ── Tags ──

export async function createTag(store: LociStore, tag: Tag): Promise<void> {
  await mkdir(tagsDir(store), { recursive: true })
  await writeFile(join(tagsDir(store), tag.name), JSON.stringify(tag, null, 2))
}

export async function listTags(store: LociStore): Promise<Tag[]> {
  const dir = tagsDir(store)
  if (!await exists(dir)) return []
  const files = await readdir(dir)
  const tags: Tag[] = []
  for (const f of files) {
    const raw = await readFile(join(dir, f), "utf-8")
    tags.push(JSON.parse(raw))
  }
  return tags.sort((a, b) => a.name.localeCompare(b.name))
}

export async function deleteTag(store: LociStore, name: string): Promise<boolean> {
  const p = join(tagsDir(store), name)
  if (!await exists(p)) return false
  await unlink(p)
  return true
}

export async function resolveTag(store: LociStore, name: string): Promise<Tag | null> {
  const p = join(tagsDir(store), name)
  if (!await exists(p)) return null
  return JSON.parse(await readFile(p, "utf-8"))
}

// ── Staging ──

export async function getStaging(store: LociStore): Promise<StagingEntry[]> {
  const p = stagingPath(store)
  if (!await exists(p)) return []
  return JSON.parse(await readFile(p, "utf-8"))
}

export async function setStaging(store: LociStore, entries: StagingEntry[]): Promise<void> {
  await writeFile(stagingPath(store), JSON.stringify(entries, null, 2))
}

export async function clearStaging(store: LociStore): Promise<void> {
  const p = stagingPath(store)
  if (await exists(p)) await unlink(p)
}

export async function stageFile(store: LociStore, path: string): Promise<StagingEntry> {
  const fullPath = join(process.cwd(), path)
  const data = await readFile(fullPath)
  const hash = await store.putBlob(new Uint8Array(data))
  const stats = await stat(fullPath)

  const staging = await getStaging(store)
  const existing = staging.findIndex(e => e.path === path)
  const entry: StagingEntry = { path, blobHash: hash, size: stats.size, action: "add" }

  // Check if file exists in HEAD tree to determine add vs modify
  const headHash = await resolveHead(store)
  if (headHash) {
    const commit = await getCommit(store, headHash)
    if (commit) {
      const tree = await getTree(store, commit.treeHash)
      if (tree?.entries.some(e => e.path === path)) {
        entry.action = "modify"
      }
    }
  }

  if (existing >= 0) staging[existing] = entry
  else staging.push(entry)

  await setStaging(store, staging)
  return entry
}

export async function stageDelete(store: LociStore, path: string): Promise<void> {
  const staging = await getStaging(store)
  const existing = staging.findIndex(e => e.path === path)
  const entry: StagingEntry = { path, blobHash: "", size: 0, action: "delete" }
  if (existing >= 0) staging[existing] = entry
  else staging.push(entry)
  await setStaging(store, staging)
}

// ── Tree manifests ──

export async function putTree(store: LociStore, manifest: TreeManifest): Promise<string> {
  await mkdir(treesDir(store), { recursive: true })
  const data = JSON.stringify(manifest, null, 2)
  const hash = new Bun.CryptoHasher("sha256").update(data).digest("hex")
  manifest.hash = hash
  await writeFile(join(treesDir(store), hash + ".json"), JSON.stringify(manifest, null, 2))
  return hash
}

export async function getTree(store: LociStore, hash: string): Promise<TreeManifest | null> {
  const p = join(treesDir(store), hash + ".json")
  if (!await exists(p)) return null
  return JSON.parse(await readFile(p, "utf-8"))
}

/** Build a tree manifest from HEAD tree + staged changes. */
export async function buildTreeFromStaging(store: LociStore): Promise<TreeManifest> {
  const staging = await getStaging(store)
  const headHash = await resolveHead(store)
  let baseEntries: TreeEntry[] = []

  if (headHash) {
    const commit = await getCommit(store, headHash)
    if (commit) {
      const tree = await getTree(store, commit.treeHash)
      if (tree) baseEntries = [...tree.entries]
    }
  }

  // Apply staging on top of base
  for (const s of staging) {
    const idx = baseEntries.findIndex(e => e.path === s.path)
    if (s.action === "delete") {
      if (idx >= 0) baseEntries.splice(idx, 1)
    } else {
      const entry: TreeEntry = { path: s.path, hash: s.blobHash, size: s.size, mode: "file" }
      if (idx >= 0) baseEntries[idx] = entry
      else baseEntries.push(entry)
    }
  }

  baseEntries.sort((a, b) => a.path.localeCompare(b.path))
  const manifest: TreeManifest = { hash: "", entries: baseEntries }
  const hash = await putTree(store, manifest)
  manifest.hash = hash
  return manifest
}

// ── Commits ──

export async function putCommit(store: LociStore, commit: Commit): Promise<string> {
  await mkdir(commitsDir(store), { recursive: true })
  const data = JSON.stringify(commit, null, 2)
  const hash = new Bun.CryptoHasher("sha256").update(data).digest("hex")
  commit.hash = hash
  await writeFile(join(commitsDir(store), hash + ".json"), data)
  return hash
}

export async function getCommit(store: LociStore, hash: string): Promise<Commit | null> {
  const p = join(commitsDir(store), hash + ".json")
  if (!await exists(p)) return null
  return JSON.parse(await readFile(p, "utf-8"))
}

/** Walk commit chain from a starting hash, up to `limit` commits. */
export async function walkCommits(store: LociStore, startHash: string | null, limit: number = 50): Promise<Commit[]> {
  const commits: Commit[] = []
  let current = startHash
  while (current && commits.length < limit) {
    const c = await getCommit(store, current)
    if (!c) break
    commits.push(c)
    current = c.parentHashes[0] ?? null
  }
  return commits
}

/** Create a commit from the current staging area. */
export async function createCommit(store: LociStore, message: string, author: string): Promise<Commit> {
  const staging = await getStaging(store)
  if (staging.length === 0) throw new Error("Nothing staged to commit")

  const tree = await buildTreeFromStaging(store)
  const parentHash = await resolveHead(store)

  const commit: Commit = {
    hash: "",
    parentHashes: parentHash ? [parentHash] : [],
    treeHash: tree.hash,
    author,
    timestamp: new Date().toISOString(),
    message,
  }

  const hash = await putCommit(store, commit)
  commit.hash = hash

  // Update branch tip
  const head = await getHead(store)
  if (head.type === "branch") {
    await setBranchTip(store, head.ref, hash)
  } else {
    await setHead(store, { type: "detached", ref: hash })
  }

  // Clear staging
  await clearStaging(store)
  return commit
}

// ── Config ──

export async function getConfig(store: LociStore): Promise<Record<string, string>> {
  const p = configPath(store)
  if (!await exists(p)) return {}
  return JSON.parse(await readFile(p, "utf-8"))
}

export async function setConfigValue(store: LociStore, key: string, value: string): Promise<void> {
  const cfg = await getConfig(store)
  cfg[key] = value
  await writeFile(configPath(store), JSON.stringify(cfg, null, 2))
}

// ── Remotes ──

export async function getRemotes(store: LociStore): Promise<RemoteConfig[]> {
  const p = remotesPath(store)
  if (!await exists(p)) return []
  return JSON.parse(await readFile(p, "utf-8"))
}

export async function addRemote(store: LociStore, remote: RemoteConfig): Promise<void> {
  const remotes = await getRemotes(store)
  if (remotes.some(r => r.name === remote.name)) throw new Error(`Remote '${remote.name}' already exists`)
  remotes.push(remote)
  await writeFile(remotesPath(store), JSON.stringify(remotes, null, 2))
}

export async function removeRemote(store: LociStore, name: string): Promise<boolean> {
  const remotes = await getRemotes(store)
  const filtered = remotes.filter(r => r.name !== name)
  if (filtered.length === remotes.length) return false
  await writeFile(remotesPath(store), JSON.stringify(filtered, null, 2))
  return true
}

// ── Stash ──

export async function stashSave(store: LociStore, message: string): Promise<StashEntry> {
  await mkdir(stashDir(store), { recursive: true })
  const staging = await getStaging(store)
  if (staging.length === 0) throw new Error("No changes to stash")
  const tree = await buildTreeFromStaging(store)
  const parentHash = await resolveHead(store) ?? ""

  const stashes = await stashList(store)
  const entry: StashEntry = {
    index: stashes.length,
    message: message || `WIP on ${(await getHead(store)).ref}`,
    timestamp: new Date().toISOString(),
    treeHash: tree.hash,
    parentHash,
  }

  stashes.push(entry)
  await writeFile(join(stashDir(store), "stash.json"), JSON.stringify(stashes, null, 2))
  await clearStaging(store)
  return entry
}

export async function stashList(store: LociStore): Promise<StashEntry[]> {
  const p = join(stashDir(store), "stash.json")
  if (!await exists(p)) return []
  return JSON.parse(await readFile(p, "utf-8"))
}

export async function stashPop(store: LociStore): Promise<StashEntry | null> {
  const stashes = await stashList(store)
  if (stashes.length === 0) return null
  const entry = stashes.pop()!
  await writeFile(join(stashDir(store), "stash.json"), JSON.stringify(stashes, null, 2))
  // Restore the tree entries as staging
  const tree = await getTree(store, entry.treeHash)
  if (tree) {
    const staging: StagingEntry[] = tree.entries.map(e => ({
      path: e.path, blobHash: e.hash, size: e.size, action: "add" as const,
    }))
    await setStaging(store, staging)
  }
  return entry
}

export async function stashDrop(store: LociStore, index?: number): Promise<boolean> {
  const stashes = await stashList(store)
  if (stashes.length === 0) return false
  if (index !== undefined) {
    const idx = stashes.findIndex(s => s.index === index)
    if (idx < 0) return false
    stashes.splice(idx, 1)
  } else {
    stashes.pop()
  }
  await writeFile(join(stashDir(store), "stash.json"), JSON.stringify(stashes, null, 2))
  return true
}

// ── Working tree scanning ──

/** Recursively list all files under a directory, excluding .loci and hidden dirs. */
export async function scanWorkingTree(root: string, prefix: string = ""): Promise<{ path: string; size: number }[]> {
  const results: { path: string; size: number }[] = []
  const dir = prefix ? join(root, prefix) : root
  if (!await exists(dir)) return results

  const entries = await readdir(dir, { withFileTypes: true })
  for (const entry of entries) {
    const relPath = prefix ? `${prefix}/${entry.name}` : entry.name
    // Skip hidden dirs, node_modules, .loci
    if (entry.name.startsWith(".") || entry.name === "node_modules" || entry.name === "_build") continue

    if (entry.isDirectory()) {
      results.push(...await scanWorkingTree(root, relPath))
    } else if (entry.isFile()) {
      const stats = await stat(join(root, relPath))
      results.push({ path: relPath, size: stats.size })
    }
  }
  return results
}

/** Compute hash for a file in the working tree. */
export async function hashFile(filePath: string): Promise<string> {
  const data = await readFile(filePath)
  return new Bun.CryptoHasher("sha256").update(new Uint8Array(data)).digest("hex")
}

/** Simple line-based diff between two strings. */
export function diffLines(oldText: string, newText: string, path: string): FileDiff {
  const oldLines = oldText.split("\n")
  const newLines = newText.split("\n")
  const hunks: DiffHunk[] = []
  const lines: DiffLine[] = []

  // Simple LCS-based diff
  let oi = 0, ni = 0
  while (oi < oldLines.length || ni < newLines.length) {
    if (oi < oldLines.length && ni < newLines.length && oldLines[oi] === newLines[ni]) {
      lines.push({ type: "context", content: oldLines[oi], oldLine: oi + 1, newLine: ni + 1 })
      oi++; ni++
    } else if (ni < newLines.length && (oi >= oldLines.length || !newLines.slice(ni).includes(oldLines[oi]))) {
      lines.push({ type: "add", content: newLines[ni], newLine: ni + 1 })
      ni++
    } else {
      lines.push({ type: "remove", content: oldLines[oi], oldLine: oi + 1 })
      oi++
    }
  }

  if (lines.some(l => l.type !== "context")) {
    hunks.push({ oldStart: 1, oldCount: oldLines.length, newStart: 1, newCount: newLines.length, lines })
  }

  return {
    path,
    status: oldText === "" ? "added" : newText === "" ? "deleted" : "modified",
    hunks,
    binary: false,
  }
}
