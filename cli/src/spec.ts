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
    {
      name: "LOCI_ENGINE",
      description: "Runtime adapter for daemon/pack/app delegation",
      example: "native",
    },
    {
      name: "LOCI_WASM_SHIM_BIN",
      description: "Binary path for wasm shim runtime adapter",
      example: "/usr/local/bin/loci-wasm-shim",
    },
    {
      name: "LOCI_WASM_SHIM_ARGS",
      description: "Extra argv appended when using wasm-shim runtime adapter",
      example: "--socket /tmp/loci.sock",
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

    // ── ide ──────────────────────────────────────────────────────────────────
    {
      name: "ide",
      description: "Cross-repo IDE surface: search, codex dropbox messaging, nucleant orchestration, and socket bridge",
      subcommands: [
        {
          name: "repo",
          description: "Manage registered peer repositories",
          subcommands: [
            {
              name: "add",
              description: "Register a repository path with a short name",
              args: [
                { name: "name", description: "Repository alias", required: true },
                { name: "path", description: "Filesystem path to repository root", required: true },
              ],
              examples: ["loci ide repo add koan ../koan"],
            },
            {
              name: "ls",
              description: "List registered repositories",
              examples: ["loci ide repo ls"],
            },
          ],
        },
        {
          name: "search",
          description: "Search across one or all registered repositories",
          args: [{ name: "query", description: "Search query text", required: true }],
          flags: [
            { name: "--repo", type: "string", description: "Target repository name or all", default: "all" },
            { name: "--limit", type: "number", description: "Maximum results returned", default: "20" },
          ],
          examples: ["loci ide search \"finger plan\" --repo all --limit 10"],
        },
        {
          name: "ask",
          description: "Send a codex message into a repository dropbox",
          args: [
            { name: "repo", description: "Target repository name", required: true },
            { name: "message", description: "Message body", required: true },
          ],
          flags: [
            { name: "--thread", type: "string", description: "Thread id to append to" },
            { name: "--from", type: "string", description: "Override sender repository name" },
          ],
          examples: ["loci ide ask koan \"sync nucleant state\" --thread nucleant-arblock-01"],
        },
        {
          name: "inbox",
          description: "Read codex dropbox messages",
          flags: [
            { name: "--repo", type: "string", description: "Read inbox from a registered repository path" },
            { name: "--thread", type: "string", description: "Filter to one thread id" },
            { name: "--limit", type: "number", description: "Maximum messages returned", default: "20" },
          ],
          examples: ["loci ide inbox --repo koan --thread nucleant-arblock-01"],
        },
        {
          name: "nucleant",
          description: "Create, fan out, and track multi-repo feature blocks",
          subcommands: [
            {
              name: "new",
              description: "Create a nucleant record",
              args: [{ name: "id", description: "Nucleant id", required: true }],
              flags: [
                { name: "--title", type: "string", description: "Human-friendly title" },
                { name: "--spec-api", type: "string", description: "Spec API reference", required: true },
                { name: "--desc", type: "string", description: "Optional description" },
              ],
              examples: ["loci ide nucleant new arblock.v1 --title \"Arblock contract\" --spec-api loci/chatgpt/LOCI-LINT-MINI-SPEC.md"],
            },
            {
              name: "present",
              description: "Present a nucleant to one or more repositories",
              args: [{ name: "id", description: "Nucleant id", required: true }],
              flags: [
                { name: "--repos", type: "string", description: "Comma-separated repo names or all", default: "all" },
                { name: "--message", type: "string", description: "Optional note appended to fanout message" },
              ],
              examples: ["loci ide nucleant present arblock.v1 --repos koan,loci --message \"begin implementation\""],
            },
            {
              name: "mark",
              description: "Update per-repo nucleant status",
              args: [{ name: "id", description: "Nucleant id", required: true }],
              flags: [
                { name: "--repo", type: "string", description: "Repository name", required: true },
                { name: "--status", type: "enum", enum: ["presented", "in_progress", "resolved"], description: "Convergence status", required: true },
                { name: "--note", type: "string", description: "Optional status note" },
              ],
              examples: ["loci ide nucleant mark arblock.v1 --repo koan --status in_progress"],
            },
            {
              name: "status",
              description: "Show all nucleants or one nucleant's convergence details",
              args: [{ name: "id", description: "Nucleant id", required: false }],
              examples: ["loci ide nucleant status", "loci ide nucleant status arblock.v1"],
            },
          ],
        },
        {
          name: "finger",
          description: "First-class finger plan operations",
          subcommands: [
            {
              name: "plan",
              description: "Emit or update finger.plan for a nucleant (including codex-locus mulsp carriers)",
              args: [{ name: "nucleant-id", description: "Nucleant id", required: true }],
              flags: [
                { name: "--out", type: "string", description: "Optional output path override" },
              ],
              examples: ["loci ide finger plan arblock.v1", "loci ide finger plan arblock.v1 --out loci/chatgpt/arblock.finger.plan"],
            },
          ],
        },
        {
          name: "codex",
          description: "Codex-locus lifecycle helpers",
          subcommands: [
            {
              name: "boot-mulsp",
              description: "Boot a mulsp nucleant, emit finger.plan, and record locality inertial diff/dedup state",
              flags: [
                { name: "--from", short: "-f", type: "string", description: "Target loci directory (default: current directory)" },
                { name: "--repos", type: "string", description: "Comma-separated repo fanout targets (or all)" },
                { name: "--id", type: "string", description: "Optional nucleant id override" },
                { name: "--title", type: "string", description: "Optional nucleant title override" },
                { name: "--spec-api", type: "string", description: "Optional spec API reference override" },
                { name: "--desc", type: "string", description: "Optional nucleant description override" },
                { name: "--message", type: "string", description: "Optional fanout message note" },
              ],
              examples: ["loci ide codex boot-mulsp -f .", "loci ide codex boot-mulsp -f ../mu --repos mu,loci"],
            },
          ],
        },
        {
          name: "componentize",
          description: "Emit module extraction skeletons from nucleants",
          subcommands: [
            {
              name: "from-nucleant",
              description: "Generate a ModuleComponentPlan-style skeleton from a nucleant id with computed confidence",
              args: [{ name: "id", description: "Nucleant id", required: true }],
              flags: [
                { name: "--module", type: "string", description: "Override generated module name" },
                { name: "--suffix", type: "string", description: "Target package suffix under zpc/genius/loci/chatgpt" },
                { name: "--status", type: "enum", enum: ["planned", "scoped", "extracted", "verified", "integrated"], description: "Componentization status for generated plan" },
                { name: "--confidence", type: "number", description: "Optional confidence override in range [0,1]" },
                { name: "--source", type: "string", description: "Comma-separated source paths override" },
                { name: "--out", type: "string", description: "Optional output path override" },
              ],
              examples: [
                "loci ide componentize from-nucleant arblock.v1",
                "loci ide componentize from-nucleant arblock.v1 --module loci.contract.blocks --suffix contracts/blocks --status verified --confidence 0.82",
              ],
            },
            {
              name: "apply",
              description: "Generate plan JSON plus a prefilled MoonBit snippet under loci/chatgpt/arblocks",
              args: [{ name: "id", description: "Nucleant id", required: true }],
              flags: [
                { name: "--module", type: "string", description: "Override generated module name" },
                { name: "--suffix", type: "string", description: "Target package suffix under zpc/genius/loci/chatgpt" },
                { name: "--status", type: "enum", enum: ["planned", "scoped", "extracted", "verified", "integrated"], description: "Componentization status for generated plan" },
                { name: "--confidence", type: "number", description: "Optional confidence override in range [0,1]" },
                { name: "--source", type: "string", description: "Comma-separated source paths override" },
                { name: "--out", type: "string", description: "Optional component plan output path override" },
                { name: "--snippet-out", type: "string", description: "Optional MoonBit snippet output path override" },
              ],
              examples: [
                "loci ide componentize apply arblock.v1",
                "loci ide componentize apply arblock.v1 --module loci.contract.blocks --suffix contracts/blocks --confidence 0.9 --snippet-out loci/chatgpt/arblocks/arblock.v1.module_componentize.mbt",
              ],
            },
          ],
        },
        {
          name: "serve",
          description: "Run stdio JSON-RPC socket bridge for loci/mcp/lsp protocols",
          examples: ["loci ide serve"],
        },
      ],
    },

    // ── status ───────────────────────────────────────────────────────────────
    {
      name: "status",
      description: "Repository overview: initialization state, loci count, sessions, open threads",
      examples: ["loci status"],
    },

    // ── spec ─────────────────────────────────────────────────────────────────
    {
      name: "run",
      description: "Docker-like loci startup: boot mulsp + nucleant + finger.plan with locality inertial diff/dedup",
      flags: [
        { name: "--from", short: "-f", type: "string", description: "Target loci directory (default: .)" },
        { name: "--repos", type: "string", description: "Comma-separated repo fanout targets (or all)" },
        { name: "--id", type: "string", description: "Optional nucleant id override" },
      ],
      examples: ["loci run -f .", "loci run -f ../loci --repos mu,loci"],
    },
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
      flags: [
        {
          name: "--engine",
          type: "enum",
          enum: ["native", "wasm-shim"],
          description: "Runtime adapter for delegation",
          default: "native",
          envVar: "LOCI_ENGINE",
        },
      ],
      delegate: "native",
      examples: [
        "loci daemon oci capabilities",
        "loci daemon oci capabilities --engine native",
        "loci daemon tree sparse --routes alpha/doc --tokens alpha",
        "loci daemon conv turn --hall saba --topic debate --content \"hello\"",
      ],
    },
    {
      name: "pack",
      description: "Delegate to native merkin binary: pack a locus sparse tree as OCI blob or WASM",
      flags: [
        {
          name: "--engine",
          type: "enum",
          enum: ["native", "wasm-shim"],
          description: "Runtime adapter for delegation",
          default: "native",
          envVar: "LOCI_ENGINE",
        },
      ],
      delegate: "native",
      examples: [
        "loci pack my-locus",
        "loci pack my-locus --format wasm",
      ],
    },
    {
      name: "app",
      description: "Delegate to native merkin binary: APP envelope put/inspect/emit-pr1/parse-pr1",
      flags: [
        {
          name: "--engine",
          type: "enum",
          enum: ["native", "wasm-shim"],
          description: "Runtime adapter for delegation",
          default: "native",
          envVar: "LOCI_ENGINE",
        },
      ],
      delegate: "native",
      examples: [
        "loci app put app://mask/entry-1 --payload \"opaque-ciphertext\" --protocol app/v1",
        "loci app inspect app://mask/entry-1",
        "loci app emit-pr1 app://mask/entry-1 --procsi-surface claude --procsi-fingerprint blake3:abc",
      ],
    },
    {
      name: "release",
      description: "Build and emit release artifacts for cli + wasm adapters",
      subcommands: [
        {
          name: "plan",
          description: "Emit release plan JSON (commands, adapters, output paths)",
          flags: [
            {
              name: "--target",
              type: "enum",
              enum: ["all", "cli", "wasm"],
              description: "Target artifact group",
              default: "all",
            },
            {
              name: "--artifacts-dir",
              type: "string",
              description: "Release artifact output directory",
              default: "../artifacts",
            },
          ],
          examples: [
            "loci release plan",
            "loci release plan --target wasm --artifacts-dir ../artifacts/nightly",
          ],
        },
        {
          name: "build",
          description: "Run build pipeline and write release-manifest.json",
          flags: [
            {
              name: "--target",
              type: "enum",
              enum: ["all", "cli", "wasm"],
              description: "Target artifact group",
              default: "all",
            },
            {
              name: "--artifacts-dir",
              type: "string",
              description: "Release artifact output directory",
              default: "../artifacts",
            },
          ],
          examples: [
            "loci release build",
            "loci release build --target cli --artifacts-dir ../artifacts/dev",
          ],
        },
      ],
    },
  ],
}
