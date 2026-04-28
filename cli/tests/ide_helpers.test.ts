import { describe, it, expect } from "bun:test"
import { mkdtempSync, rmSync, mkdirSync, writeFileSync } from "fs"
import { join } from "path"
import { tmpdir } from "os"
import { __ideInternals } from "../src/commands/ide.ts"

describe("ide repo nesting helpers", () => {
  it("detects ancestor relationships", () => {
    expect(__ideInternals.isAncestorPath("/a/b", "/a/b/c")).toBe(true)
    expect(__ideInternals.isAncestorPath("/a/b", "/a/b")).toBe(false)
    expect(__ideInternals.isAncestorPath("/a/b", "/a/bb")).toBe(false)
  })

  it("sorts repos by depth then name", () => {
    const sorted = __ideInternals.sortRepos([
      { name: "sdk", path: "/root/workspace/modules/sdk" },
      { name: "workspace", path: "/root/workspace" },
      { name: "api", path: "/root/workspace/modules/api" },
    ])
    expect(sorted.map(r => r.name)).toEqual(["workspace", "api", "sdk"])
  })

  it("reports nested under/over relations for recursive module repos", () => {
    const repos = __ideInternals.sortRepos([
      { name: "workspace", path: "/root/workspace" },
      { name: "sdk", path: "/root/workspace/modules/sdk" },
    ])
    const workspaceRels = __ideInternals.nestedRelationsFor("workspace", "/root/workspace", repos)
    const sdkRels = __ideInternals.nestedRelationsFor("sdk", "/root/workspace/modules/sdk", repos)
    expect(workspaceRels).toEqual([{ other: "sdk", path: "/root/workspace/modules/sdk", direction: "over" }])
    expect(sdkRels).toEqual([{ other: "workspace", path: "/root/workspace", direction: "under" }])
  })
})

describe("canonicalRepoPath", () => {
  it("normalizes valid directories", async () => {
    const root = mkdtempSync(join(tmpdir(), "loci-ide-canon-"))
    try {
      const dir = join(root, "workspace")
      mkdirSync(dir, { recursive: true })
      const canonical = await __ideInternals.canonicalRepoPath(dir + "/")
      expect(canonical.endsWith("/workspace")).toBe(true)
    } finally {
      rmSync(root, { recursive: true, force: true })
    }
  })

  it("rejects missing paths and files", async () => {
    const root = mkdtempSync(join(tmpdir(), "loci-ide-canon-"))
    try {
      const file = join(root, "note.txt")
      writeFileSync(file, "x")

      await expect(__ideInternals.canonicalRepoPath(join(root, "missing"))).rejects.toThrow("repo path does not exist")
      await expect(__ideInternals.canonicalRepoPath(file)).rejects.toThrow("repo path is not a directory")
    } finally {
      rmSync(root, { recursive: true, force: true })
    }
  })
})
