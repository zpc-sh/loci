// Conformance tests for the CLI spec.
//
// These tests validate the spec data structure itself — shape invariants,
// completeness against the dispatch table in index.ts, and JSON serializability.
// If a command or flag is added to index.ts, a corresponding spec entry must exist.

import { describe, it, expect } from "bun:test"
import { CLI_SPEC, type CommandSpec, type FlagSpec } from "../src/spec.ts"
import { renderSpecMarkdown } from "../src/commands/spec.ts"

// ── spec shape invariants ────────────────────────────────────────────────────

describe("CLI_SPEC: top-level shape", () => {
  it("has name, version, and description", () => {
    expect(CLI_SPEC.name).toBe("loci")
    expect(CLI_SPEC.version).toMatch(/^\d+\.\d+\.\d+$/)
    expect(CLI_SPEC.description.length).toBeGreaterThan(10)
  })

  it("has at least one global flag", () => {
    expect(CLI_SPEC.globals.length).toBeGreaterThan(0)
  })

  it("has at least three env vars", () => {
    expect(CLI_SPEC.env.length).toBeGreaterThanOrEqual(3)
  })

  it("has at least one command", () => {
    expect(CLI_SPEC.commands.length).toBeGreaterThan(0)
  })
})

describe("CLI_SPEC: global flags", () => {
  it("all global flags start with --", () => {
    for (const f of CLI_SPEC.globals) {
      expect(f.name).toMatch(/^--/)
    }
  })

  it("all global flags have non-empty descriptions", () => {
    for (const f of CLI_SPEC.globals) {
      expect(f.description.length).toBeGreaterThan(0)
    }
  })

  it("includes --loci-root", () => {
    expect(CLI_SPEC.globals.map(f => f.name)).toContain("--loci-root")
  })

  it("includes --store", () => {
    expect(CLI_SPEC.globals.map(f => f.name)).toContain("--store")
  })

  it("includes --locus", () => {
    expect(CLI_SPEC.globals.map(f => f.name)).toContain("--locus")
  })
})

describe("CLI_SPEC: env vars", () => {
  const names = CLI_SPEC.env.map(e => e.name)

  it("includes LOCI_LOCUS", () => expect(names).toContain("LOCI_LOCUS"))
  it("includes LOCI_TIER", () => expect(names).toContain("LOCI_TIER"))
  it("includes LOCI_SESSION", () => expect(names).toContain("LOCI_SESSION"))

  it("all env vars have non-empty descriptions", () => {
    for (const e of CLI_SPEC.env) {
      expect(e.description.length).toBeGreaterThan(0)
    }
  })
})

// ── flag validation helpers ──────────────────────────────────────────────────

function walkFlags(cmd: CommandSpec, visitor: (f: FlagSpec, path: string) => void, path = ""): void {
  const cmdPath = path ? `${path} ${cmd.name}` : cmd.name
  for (const f of cmd.flags ?? []) visitor(f, cmdPath)
  for (const sub of cmd.subcommands ?? []) walkFlags(sub, visitor, cmdPath)
}

describe("CLI_SPEC: flag invariants (all commands)", () => {
  it("every flag name starts with --", () => {
    for (const cmd of CLI_SPEC.commands) {
      walkFlags(cmd, (f, path) => {
        expect(f.name, `${path}: flag name should start with --`).toMatch(/^--/)
      })
    }
  })

  it("every flag has a non-empty description", () => {
    for (const cmd of CLI_SPEC.commands) {
      walkFlags(cmd, (f, path) => {
        expect(f.description.length, `${path} ${f.name}: description should not be empty`).toBeGreaterThan(0)
      })
    }
  })

  it("enum flags have at least one option", () => {
    for (const cmd of CLI_SPEC.commands) {
      walkFlags(cmd, (f, path) => {
        if (f.type === "enum") {
          expect(f.enum, `${path} ${f.name}: enum flag needs options`).toBeDefined()
          expect(f.enum!.length, `${path} ${f.name}: enum flag needs at least one option`).toBeGreaterThan(0)
        }
      })
    }
  })

  it("boolean flags have no enum values", () => {
    for (const cmd of CLI_SPEC.commands) {
      walkFlags(cmd, (f, path) => {
        if (f.type === "boolean") {
          expect(f.enum, `${path} ${f.name}: boolean flag should not have enum values`).toBeUndefined()
        }
      })
    }
  })
})

// ── arg validation helpers ───────────────────────────────────────────────────

function walkArgs(cmd: CommandSpec, visitor: (a: { name: string; description: string; required: boolean }, path: string) => void, path = ""): void {
  const cmdPath = path ? `${path} ${cmd.name}` : cmd.name
  for (const a of cmd.args ?? []) visitor(a, cmdPath)
  for (const sub of cmd.subcommands ?? []) walkArgs(sub, visitor, cmdPath)
}

describe("CLI_SPEC: arg invariants (all commands)", () => {
  it("every arg has a non-empty name", () => {
    for (const cmd of CLI_SPEC.commands) {
      walkArgs(cmd, (a, path) => {
        expect(a.name.length, `${path}: arg name should not be empty`).toBeGreaterThan(0)
      })
    }
  })

  it("every arg has a non-empty description", () => {
    for (const cmd of CLI_SPEC.commands) {
      walkArgs(cmd, (a, path) => {
        expect(a.description.length, `${path} <${a.name}>: arg description should not be empty`).toBeGreaterThan(0)
      })
    }
  })
})

// ── command surface completeness ─────────────────────────────────────────────
// Every command dispatched in index.ts must have a spec entry.

describe("CLI_SPEC: command surface completeness", () => {
  const topLevel = CLI_SPEC.commands.map(c => c.name)

  // Top-level commands from index.ts dispatch table
  const required = [
    "init", "loci", "genius",
    "enter", "sign", "trail", "residue", "where",
    "ide", "status", "spec",
    "daemon", "pack", "app",
  ]

  for (const name of required) {
    it(`has top-level command: ${name}`, () => {
      expect(topLevel, `missing top-level command: ${name}`).toContain(name)
    })
  }

  it("loci has subcommands: new, ls", () => {
    const loci = CLI_SPEC.commands.find(c => c.name === "loci")!
    expect(loci).toBeDefined()
    const subs = (loci.subcommands ?? []).map(s => s.name)
    expect(subs).toContain("new")
    expect(subs).toContain("ls")
  })

  it("genius has subcommands: enter, sign, trail, residue, where", () => {
    const genius = CLI_SPEC.commands.find(c => c.name === "genius")!
    expect(genius).toBeDefined()
    const subs = (genius.subcommands ?? []).map(s => s.name)
    for (const s of ["enter", "sign", "trail", "residue", "where"]) {
      expect(subs, `genius missing subcommand: ${s}`).toContain(s)
    }
  })

  it("ide has subcommands: repo, search, ask, inbox, nucleant, finger, componentize, serve", () => {
    const ide = CLI_SPEC.commands.find(c => c.name === "ide")!
    expect(ide).toBeDefined()
    const subs = (ide.subcommands ?? []).map(s => s.name)
    for (const s of ["repo", "search", "ask", "inbox", "nucleant", "finger", "componentize", "serve"]) {
      expect(subs, `ide missing subcommand: ${s}`).toContain(s)
    }
  })

  it("ide componentize has subcommands: from-nucleant, apply", () => {
    const ide = CLI_SPEC.commands.find(c => c.name === "ide")!
    expect(ide).toBeDefined()
    const componentize = (ide.subcommands ?? []).find(s => s.name === "componentize")
    expect(componentize).toBeDefined()
    const subs = (componentize!.subcommands ?? []).map(s => s.name)
    for (const s of ["from-nucleant", "apply"]) {
      expect(subs, `ide componentize missing subcommand: ${s}`).toContain(s)
    }
  })
})

// ── specific flag checks ──────────────────────────────────────────────────────

describe("CLI_SPEC: specific flag coverage", () => {
  const genius = () => CLI_SPEC.commands.find(c => c.name === "genius")!

  it("genius enter has --export flag (boolean)", () => {
    const enter = genius().subcommands!.find(s => s.name === "enter")!
    const f = (enter.flags ?? []).find(f => f.name === "--export")
    expect(f).toBeDefined()
    expect(f!.type).toBe("boolean")
  })

  it("genius enter has --tier flag (enum: haiku|sonnet|opus)", () => {
    const enter = genius().subcommands!.find(s => s.name === "enter")!
    const f = (enter.flags ?? []).find(f => f.name === "--tier")!
    expect(f).toBeDefined()
    expect(f.type).toBe("enum")
    expect(f.enum).toContain("haiku")
    expect(f.enum).toContain("sonnet")
    expect(f.enum).toContain("opus")
  })

  it("genius sign has --locus flag with LOCI_LOCUS env var", () => {
    const sign = genius().subcommands!.find(s => s.name === "sign")!
    const f = (sign.flags ?? []).find(f => f.name === "--locus")!
    expect(f).toBeDefined()
    expect(f.envVar).toBe("LOCI_LOCUS")
  })

  it("genius trail has --depth flag (number, default 10)", () => {
    const trail = genius().subcommands!.find(s => s.name === "trail")!
    const f = (trail.flags ?? []).find(f => f.name === "--depth")!
    expect(f).toBeDefined()
    expect(f.type).toBe("number")
    expect(f.default).toBe("10")
  })

  it("spec command has --format flag (enum: json|markdown)", () => {
    const spec = CLI_SPEC.commands.find(c => c.name === "spec")!
    expect(spec).toBeDefined()
    const f = (spec.flags ?? []).find(f => f.name === "--format")!
    expect(f).toBeDefined()
    expect(f.type).toBe("enum")
    expect(f.enum).toContain("json")
    expect(f.enum).toContain("markdown")
    expect(f.default).toBe("json")
  })

  it("spec command has --out flag (string)", () => {
    const spec = CLI_SPEC.commands.find(c => c.name === "spec")!
    const f = (spec.flags ?? []).find(f => f.name === "--out")!
    expect(f).toBeDefined()
    expect(f.type).toBe("string")
  })
})

// ── delegate commands ─────────────────────────────────────────────────────────

describe("CLI_SPEC: native delegate commands", () => {
  for (const name of ["daemon", "pack", "app"]) {
    it(`${name} is marked as delegate: "native"`, () => {
      const cmd = CLI_SPEC.commands.find(c => c.name === name)!
      expect(cmd).toBeDefined()
      expect(cmd.delegate).toBe("native")
    })
  }
})

// ── serialization ─────────────────────────────────────────────────────────────

describe("CLI_SPEC: JSON serialization", () => {
  it("serializes to valid JSON", () => {
    const json = JSON.stringify(CLI_SPEC)
    expect(() => JSON.parse(json)).not.toThrow()
  })

  it("round-trips name and command count", () => {
    const rt = JSON.parse(JSON.stringify(CLI_SPEC))
    expect(rt.name).toBe(CLI_SPEC.name)
    expect(rt.commands.length).toBe(CLI_SPEC.commands.length)
    expect(rt.version).toBe(CLI_SPEC.version)
  })
})

// ── markdown emission ────────────────────────────────────────────────────────

describe("CLI_SPEC: markdown emission", () => {
  let md: string

  it("renders without throwing", () => {
    expect(() => { md = renderSpecMarkdown(CLI_SPEC) }).not.toThrow()
  })

  it("contains the CLI name in the title", () => {
    md = renderSpecMarkdown(CLI_SPEC)
    expect(md).toContain(`# ${CLI_SPEC.name}`)
  })

  it("contains every top-level command name", () => {
    md = renderSpecMarkdown(CLI_SPEC)
    for (const cmd of CLI_SPEC.commands) {
      expect(md, `markdown should contain command: ${cmd.name}`).toContain(cmd.name)
    }
  })

  it("contains ## Global Flags section", () => {
    expect(md).toContain("## Global Flags")
  })

  it("contains ## Environment Variables section", () => {
    expect(md).toContain("## Environment Variables")
  })

  it("contains ## Commands section", () => {
    expect(md).toContain("## Commands")
  })

  it("contains the auto-generated notice", () => {
    expect(md).toContain("Auto-generated by `loci spec --format markdown`")
  })

  it("contains sh code fences for examples", () => {
    expect(md).toContain("```sh")
  })
})
