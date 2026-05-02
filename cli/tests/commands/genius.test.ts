// Integration tests for genius commands: enter, sign, trail, residue, where.
//
// These spawn the actual CLI process in a temp directory and check:
// - exit codes (0 = success, 1 = usage error)
// - stdout for expected output patterns
// - that shell-eval output (--export) is properly quoted
//
// Each test is self-contained: it creates a fresh temp loci root.

import { describe, it, expect, beforeAll, afterAll } from "bun:test"
import { mkdtempSync, rmSync, mkdirSync, writeFileSync } from "fs"
import { join, resolve } from "path"
import { tmpdir } from "os"

const CLI = resolve(import.meta.dir, "../../src/index.ts")
const CLI_DIR = resolve(import.meta.dir, "../..")

// ── test harness ──────────────────────────────────────────────────────────────
// Always run from cli/ so bun can resolve node_modules (@clack/prompts etc).
// Use absolute paths for --loci-root / --store flags.

interface RunResult {
  out: string
  err: string
  code: number
}

async function run(
  args: string[],
  opts: { env?: Record<string, string> } = {},
): Promise<RunResult> {
  const proc = Bun.spawn(
    ["bun", "run", CLI, ...args],
    {
      stdout: "pipe",
      stderr: "pipe",
      cwd: CLI_DIR,
      env: { ...process.env, ...(opts.env ?? {}) },
    },
  )
  const [out, err, code] = await Promise.all([
    new Response(proc.stdout).text(),
    new Response(proc.stderr).text(),
    proc.exited,
  ])
  return { out, err, code }
}

// ── shared temp root ──────────────────────────────────────────────────────────
// Each helper returns an absolute loci-root path inside the shared tmpRoot.
// Pass it as --loci-root <abs-path> so CLI can always find it regardless of cwd.

let tmpRoot: string

beforeAll(() => {
  tmpRoot = mkdtempSync(join(tmpdir(), "loci-test-"))
})

afterAll(() => {
  rmSync(tmpRoot, { recursive: true, force: true })
})

function makeLociRoot(prefix: string): string {
  const dir = mkdtempSync(join(tmpRoot, prefix + "-"))
  const loci = join(dir, "loci")
  mkdirSync(loci, { recursive: true })
  return loci
}

// ── spec command ──────────────────────────────────────────────────────────────

describe("loci spec", () => {
  it("exits 0 and emits valid JSON by default", async () => {
    const { out, code } = await run(["spec"])
    expect(code).toBe(0)
    const parsed = JSON.parse(out)
    expect(parsed.name).toBe("loci")
    expect(Array.isArray(parsed.commands)).toBe(true)
  })

  it("--format json emits valid JSON", async () => {
    const { out, code } = await run(["spec", "--format", "json"])
    expect(code).toBe(0)
    const parsed = JSON.parse(out)
    expect(parsed.version).toMatch(/^\d+\.\d+\.\d+$/)
  })

  it("--format markdown emits markdown with command names", async () => {
    const { out, code } = await run(["spec", "--format", "markdown"])
    expect(code).toBe(0)
    expect(out).toContain("# loci")
    expect(out).toContain("## Commands")
    expect(out).toContain("`init`")
    expect(out).toContain("`genius`")
    expect(out).toContain("`spec`")
  })

  it("--format unknown exits 1", async () => {
    const { code } = await run(["spec", "--format", "xml"])
    expect(code).toBe(1)
  })

  it("spec command appears in its own JSON output (self-describing)", async () => {
    const { out } = await run(["spec"])
    const parsed = JSON.parse(out)
    const names: string[] = parsed.commands.map((c: { name: string }) => c.name)
    expect(names).toContain("spec")
  })
})

// ── genius enter ─────────────────────────────────────────────────────────────

describe("loci genius enter", () => {
  it("exits 1 with no locus argument", async () => {
    const { code, err } = await run(["genius", "enter"])
    expect(code).toBe(1)
    expect(err).toContain("locus")
  })

  it("exits 0 for a valid locus name and shows locus name", async () => {
    const { out, code } = await run(["genius", "enter", "test-locus"])
    expect(code).toBe(0)
    expect(out).toContain("test-locus")
  })

  it("--export emits eval-able export lines", async () => {
    const { out, code } = await run(["genius", "enter", "my-locus", "--export"])
    expect(code).toBe(0)
    expect(out).toContain("export LOCI_LOCUS=")
    expect(out).toContain("export LOCI_TIER=")
    expect(out).toContain("export LOCI_SESSION=")
  })

  it("--export single-quotes locus name (shell injection safety)", async () => {
    const { out, code } = await run(["genius", "enter", "my-locus", "--export"])
    expect(code).toBe(0)
    expect(out).toContain("LOCI_LOCUS='my-locus'")
  })

  it("--export with --tier uses the given tier", async () => {
    const { out, code } = await run(["genius", "enter", "x", "--export", "--tier", "opus"])
    expect(code).toBe(0)
    expect(out).toContain("LOCI_TIER='opus'")
  })

  it("non-export path shows LOCI_ env lines (no export keyword)", async () => {
    const { out, code } = await run(["genius", "enter", "my-locus"])
    expect(code).toBe(0)
    expect(out).toContain("LOCI_LOCUS=my-locus")
    expect(out).not.toContain("export LOCI_LOCUS")
  })

  it("short alias `loci enter` behaves the same as `loci genius enter`", async () => {
    const [full, alias] = await Promise.all([
      run(["genius", "enter", "x"]),
      run(["enter", "x"]),
    ])
    expect(full.code).toBe(alias.code)
    expect(full.out).toContain("x")
    expect(alias.out).toContain("x")
  })
})

// ── genius trail ─────────────────────────────────────────────────────────────

describe("loci genius trail", () => {
  it("exits 1 with no locus argument", async () => {
    const { code, err } = await run(["genius", "trail"])
    expect(code).toBe(1)
    expect(err).toContain("locus")
  })

  it("exits 0 for an empty locus and shows 0 sessions", async () => {
    const lociRoot = makeLociRoot("trail")
    const { out, code } = await run(["genius", "trail", "ghost-locus", "--loci-root", lociRoot])
    expect(code).toBe(0)
    expect(out).toContain("ghost-locus")
    expect(out).toContain("0 sessions")
  })

  it("short alias `loci trail` exits 0", async () => {
    const lociRoot = makeLociRoot("trail2")
    const { code } = await run(["trail", "ghost-locus", "--loci-root", lociRoot])
    expect(code).toBe(0)
  })
})

// ── genius sign ──────────────────────────────────────────────────────────────

describe("loci genius sign", () => {
  it("exits 1 with no locus context", async () => {
    const lociRoot = makeLociRoot("sign")
    // Unset LOCI_LOCUS so no ambient context is available
    const env: Record<string, string> = { ...process.env }
    delete env["LOCI_LOCUS"]
    const proc = Bun.spawn(
      ["bun", "run", CLI, "genius", "sign", "--loci-root", lociRoot],
      { stdout: "pipe", stderr: "pipe", cwd: CLI_DIR, env },
    )
    const [, err, code] = await Promise.all([
      new Response(proc.stdout).text(),
      new Response(proc.stderr).text(),
      proc.exited,
    ])
    expect(code).toBe(1)
    expect(err).toContain("locus")
  })

  it("exits 0 when LOCI_LOCUS is set via env", async () => {
    const lociRoot = makeLociRoot("sign-env")
    mkdirSync(join(lociRoot, "my-locus", "residue"), { recursive: true })
    const { code } = await run(
      ["genius", "sign", "did something", "--loci-root", lociRoot],
      { env: { LOCI_LOCUS: "my-locus", LOCI_SESSION: "sonnet/aabbcc" } },
    )
    expect(code).toBe(0)
  })
})

// ── genius residue ────────────────────────────────────────────────────────────

describe("loci genius residue", () => {
  it("shows 'No residue found' for a locus with no residues", async () => {
    const lociRoot = makeLociRoot("residue")
    const { out, code } = await run(
      ["genius", "residue", "empty-locus", "--loci-root", lociRoot],
    )
    expect(code).toBe(0)
    expect(out).toContain("No residue found")
  })
})

// ── genius where ─────────────────────────────────────────────────────────────

describe("loci genius where", () => {
  it("exits 0 with empty loci root", async () => {
    const lociRoot = makeLociRoot("where")
    const { code } = await run(["genius", "where", "--loci-root", lociRoot])
    expect(code).toBe(0)
  })

  it("shows header row with LOCUS column", async () => {
    const lociRoot = makeLociRoot("where2")
    const { out } = await run(["genius", "where", "--loci-root", lociRoot])
    expect(out).toContain("LOCUS")
  })
})

// ── status ────────────────────────────────────────────────────────────────────

describe("loci status", () => {
  it("exits 0 in an un-initialized directory", async () => {
    const lociRoot = makeLociRoot("status")
    const { code, out } = await run(["status", "--loci-root", lociRoot])
    expect(code).toBe(0)
    expect(out).toContain("Loci root:")
  })
})

// ── unknown command ───────────────────────────────────────────────────────────

describe("loci: unknown command handling", () => {
  it("exits 1 for an unknown command", async () => {
    const { code, err } = await run(["not-a-real-command-xyz"])
    expect(code).toBe(1)
    expect(err).toContain("Unknown command")
  })

  it("exits 0 for no arguments (shows usage)", async () => {
    const { code } = await run([])
    expect(code).toBe(0)
  })

  it("exits 0 for --help", async () => {
    const { code, out } = await run(["--help"])
    expect(code).toBe(0)
    expect(out).toContain("loci")
  })
})
