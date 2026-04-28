import { mkdir, exists, stat, realpath } from "fs/promises"
import { resolve } from "path"

export interface RepoEntry {
  name: string
  path: string
}

export interface IdeConfig {
  repos: RepoEntry[]
}

export type NestedRelation = {
  other: string
  path: string
  direction: "under" | "over"
}

export function isAncestorPath(parent: string, child: string): boolean {
  if (parent === child) return false
  const normalizedParent = parent.replace(/\/+$/, "")
  const normalizedChild = child.replace(/\/+$/, "")
  return normalizedChild.startsWith(`${normalizedParent}/`)
}

export function sortRepos(repos: RepoEntry[]): RepoEntry[] {
  return [...repos].sort((a, b) => {
    const aDepth = a.path.split("/").length
    const bDepth = b.path.split("/").length
    if (aDepth !== bDepth) return aDepth - bDepth
    return a.name.localeCompare(b.name)
  })
}

export function nestedRelationsFor(name: string, path: string, repos: RepoEntry[]): NestedRelation[] {
  const relations: NestedRelation[] = []
  for (const other of repos) {
    if (other.name === name) continue
    if (isAncestorPath(other.path, path)) {
      relations.push({ other: other.name, path: other.path, direction: "under" })
      continue
    }
    if (isAncestorPath(path, other.path)) {
      relations.push({ other: other.name, path: other.path, direction: "over" })
    }
  }
  return relations.sort((a, b) => a.other.localeCompare(b.other))
}

export async function canonicalRepoPath(pathArg: string): Promise<string> {
  const absPath = resolve(pathArg)
  if (!await exists(absPath)) {
    throw new Error(`repo path does not exist: ${absPath}`)
  }
  const meta = await stat(absPath)
  if (!meta.isDirectory()) {
    throw new Error(`repo path is not a directory: ${absPath}`)
  }
  return await realpath(absPath)
}

export async function loadIdeConfig(ideReposFile: string): Promise<IdeConfig> {
  if (!await exists(ideReposFile)) return { repos: [] }
  try {
    const parsed = JSON.parse(await Bun.file(ideReposFile).text()) as IdeConfig
    return { repos: Array.isArray(parsed.repos) ? parsed.repos : [] }
  } catch {
    return { repos: [] }
  }
}

export async function saveIdeConfig(ideRoot: string, ideReposFile: string, config: IdeConfig): Promise<void> {
  await mkdir(ideRoot, { recursive: true })
  await Bun.write(ideReposFile, JSON.stringify(config, null, 2))
}
