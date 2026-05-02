// Machine-readable CLI spec. Single source of truth for the loci command surface.
//
// Every command, subcommand, flag, arg, and env var is declared here.
// Conformance tests (cli/tests/spec.test.ts) validate the spec shape.
// The `loci spec` command emits this as JSON or markdown for site consumption.
//
// When adding a command: add it here first, then implement it.
// When removing a command: remove it here and from index.ts together.

export type FlagType = "string" | "number" | "boolean" | "enum"

export interface FlagSpec {
  name: string          // --flag-name
  short?: string        // -f (single-char alias)
  type: FlagType
  enum?: readonly string[]
  description: string
  default?: string
  required?: boolean
  envVar?: string       // env var that overrides this flag
}

export interface ArgSpec {
  name: string
  description: string
  required: boolean
}

export interface CommandSpec {
  name: string
  aliases?: readonly string[]
  description: string
  args?: readonly ArgSpec[]
  flags?: readonly FlagSpec[]
  subcommands?: readonly CommandSpec[]
  examples?: readonly string[]
  delegate?: "native"   // command delegates entirely to the native merkin binary
}

export interface EnvVarSpec {
  name: string
  description: string
  example?: string
  setBy?: string        // which command/flag sets this
}

export interface CliSpec {
  name: string
  version: string
  description: string
  globals: readonly FlagSpec[]
  env: readonly EnvVarSpec[]
  commands: readonly CommandSpec[]
}

export const TIER_VALUES = ["haiku", "sonnet", "opus"] as const

const TIER_FLAG: FlagSpec = {
  name: "--tier",
  type: "enum",
  enum: TIER_VALUES,
  description: "Claude tier for this session",
  default: "sonnet",
  envVar: "LOCI_TIER",
}

const LOCUS_FLAG: FlagSpec = {
  name: "--locus",
  type: "string",
  description: "Target locus name",
  envVar: "LOCI_LOCUS",
}

export const CLI_SPEC: CliSpec = {
  name: "loci",
  version: "0.1.0",
  description:
    "L-OCI content-addressed locus CLI — AI inhabitation and stigmergy surface for the Merkin/Genius stack",

  globals: [
    {
      name: "--loci-root",
      type: "string",
      description: "Loci directory root",
      default: "loci",
    },
    {
      name: "--store",
      type: "string",
      description: "OCI blob store path",
      default: ".loci/store",
    },
    { ...LOCUS_FLAG, description: "Override current locus (or set LOCI_LOCUS)" },
  ],

  env: [
    {
      name: "LOCI_LOCUS",
      description: "Current locus name (set via: eval $(loci enter <name> --export))",
      example: "my-locus",
      setBy: "genius enter --export",
    },
    {
      name: "LOCI_TIER",
      description: "Claude tier for this session",
      example: "sonnet",
      setBy: "genius enter --export",
    },
    {
      name: "LOCI_SESSION",
      description: "tier/shortId pair identifying the current session",
      example: "sonnet/a1b2c3",
      setBy: "genius enter --export",
    },
    {
      name: "LOCI_GENIUS_ROOT",
      description: "Path to genius loci source root (overrides auto-detection for daemon delegation)",
      example: "/home/user/loci",
    },
    {
      name: "LOCI_MERKIN_ROOT",
      description: "Path to merkin repo root for native binary delegation (used by LociCore)",
      example: "/home/user/loci",
    },
  ],

  commands: [
    // ── init ────────────────────────────────────────────────────────────────
    {
      name: "init",
      description: "Initialize loci root and OCI store in the current directory",
      examples: [
        "loci init",
        "loci init --store .custom/store",
      ],
    },

    // ── loci / ratio ─────────────────────────────────────────────────────────
    {
      name: "loci",
      aliases: ["ratio"],
      description: "Ratio Loci commands: locus scaffolding and repository-principal operations",
      subcommands: [
        {
          name: "new",
          description: "Scaffold a new locus directory with standard subdirs and README",
          args: [{ name: "name", description: "Locus name (becomes directory under loci/)", required: true }],
          flags: [
            { name: "--spirit", type: "string", description: "One-line purpose for this locus" },
            { name: "--tags", type: "string", description: "Comma-separated tag list" },
          ],
          examples: [
            "loci loci new claude-work",
            "loci loci new claude-work --spirit \"exploration surface\" --tags ai,analysis",
          ],
        },
        {
          name: "ls",
          description: "List all loci with last session overview",
          examples: ["loci loci ls"],
        },
      ],
    },

    // ── genius ───────────────────────────────────────────────────────────────
    {
      name: "genius",
      description: "Genius Loci commands: AI inhabitation, trail, and residue surface",
      subcommands: [
        {
          name: "enter",
          description:
            "Print enter preamble for a locus and emit session env (tier, shortId). " +
            "With --export, output is eval-able shell assignments.",
          args: [{ name: "locus", description: "Locus to enter", required: true }],
          flags: [
            {
              name: "--export",
              type: "boolean",
              description: "Print eval-able `export VAR=value` lines for shell env setup",
            },
            TIER_FLAG,
          ],
          examples: [
            "loci genius enter my-locus",
            "eval $(loci genius enter my-locus --export)",
            "loci genius enter my-locus --tier opus --export",
          ],
        },
        {
          name: "sign",
          description:
            "File an exit residue for the current session. " +
            "Interactive if stdin is a TTY; non-interactive if piped.",
          args: [
            {
              name: "message",
              description: "What you did (positional shorthand for non-interactive use)",
              required: false,
            },
          ],
          flags: [
            LOCUS_FLAG,
            TIER_FLAG,
          ],
          examples: [
            "loci genius sign",
            "loci genius sign \"implemented spec emitter and tests\"",
            "loci genius sign --locus my-locus --tier sonnet",
          ],
        },
        {
          name: "trail",
          description: "Show the session trail (residue history) for a locus",
          args: [{ name: "locus", description: "Locus to inspect", required: true }],
          flags: [
            {
              name: "--depth",
              type: "number",
              description: "Number of sessions to show",
              default: "10",
            },
          ],
          examples: [
            "loci genius trail my-locus",
            "loci genius trail my-locus --depth 5",
          ],
        },
        {
          name: "residue",
          description: "Show the latest residue for a locus",
          args: [{ name: "locus", description: "Locus to inspect", required: true }],
          examples: ["loci genius residue my-locus"],
        },
        {
          name: "where",
          description: "Overview table of all loci with last session and open threads",
          examples: ["loci genius where"],
        },
      ],
    },

    // ── short aliases ────────────────────────────────────────────────────────
    {
      name: "enter",
      description: "Alias for `genius enter`",
      args: [{ name: "locus", description: "Locus to enter", required: true }],
      flags: [
        { name: "--export", type: "boolean", description: "Emit eval-able export lines" },
        TIER_FLAG,
      ],
      examples: ["loci enter my-locus", "eval $(loci enter my-locus --export)"],
    },
    {
      name: "sign",
      description: "Alias for `genius sign`",
      args: [{ name: "message", description: "What you did", required: false }],
      flags: [LOCUS_FLAG, TIER_FLAG],
      examples: ["loci sign", "loci sign \"finished the spec refactor\""],
    },
    {
      name: "trail",
      description: "Alias for `genius trail`",
      args: [{ name: "locus", description: "Locus to inspect", required: true }],
      flags: [{ name: "--depth", type: "number", description: "Trail depth limit", default: "10" }],
      examples: ["loci trail my-locus --depth 3"],
    },
    {
      name: "residue",
      description: "Alias for `genius residue`",
      args: [{ name: "locus", description: "Locus to inspect", required: true }],
      examples: ["loci residue my-locus"],
    },
    {
      name: "where",
      description: "Alias for `genius where`",
      examples: ["loci where"],
    },

    // ── status ───────────────────────────────────────────────────────────────
    {
      name: "status",
      description: "Repository overview: initialization state, loci count, sessions, open threads",
      examples: ["loci status"],
    },

    // ── spec ─────────────────────────────────────────────────────────────────
    {
      name: "spec",
      description:
        "Emit the full CLI spec as JSON (default) or markdown. " +
        "JSON is the machine-readable contract; markdown is site-ready documentation. " +
        "This command is self-describing — it appears in its own output.",
      flags: [
        {
          name: "--format",
          type: "enum",
          enum: ["json", "markdown"],
          description: "Output format",
          default: "json",
        },
        {
          name: "--out",
          type: "string",
          description: "Write output to a file instead of stdout",
        },
      ],
      examples: [
        "loci spec",
        "loci spec --format markdown",
        "loci spec --format markdown --out docs/CLI_SPEC_v0.1.md",
        "loci spec | jq '.commands[].name'",
      ],
    },

    // ── native delegates ─────────────────────────────────────────────────────
    {
      name: "daemon",
      description: "Delegate to native merkin binary: tree/bloom/OCI/conversational daemon ops",
      delegate: "native",
      examples: [
        "loci daemon oci capabilities",
        "loci daemon tree sparse --routes alpha/doc --tokens alpha",
        "loci daemon conv turn --hall saba --topic debate --content \"hello\"",
      ],
    },
    {
      name: "pack",
      description: "Delegate to native merkin binary: pack a locus sparse tree as OCI blob or WASM",
      delegate: "native",
      examples: [
        "loci pack my-locus",
        "loci pack my-locus --format wasm",
      ],
    },
    {
      name: "app",
      description: "Delegate to native merkin binary: APP envelope put/inspect/emit-pr1/parse-pr1",
      delegate: "native",
      examples: [
        "loci app put app://mask/entry-1 --payload \"opaque-ciphertext\" --protocol app/v1",
        "loci app inspect app://mask/entry-1",
        "loci app emit-pr1 app://mask/entry-1 --procsi-surface claude --procsi-fingerprint blake3:abc",
      ],
    },
  ],
}
