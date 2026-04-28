import { mkdir, exists, readdir } from "fs/promises"
import { dirname, join, resolve } from "path"

export type ReleaseTarget = "all" | "cli" | "wasm" | "wasm-gc"

export interface ReleasePlan {
  timestamp: string
  cli_root: string
  repo_root: string
  artifacts_dir: string
  targets: ReleaseTarget[]
  engine_adapters: string[]
  commands: string[]
}

export interface ReleaseArtifact {
  kind: "bun-cli" | "wasm" | "manifest"
  path: string
  note?: string
}

export interface ReleaseManifest {
  generated_at: string
  artifacts_dir: string
  targets: ReleaseTarget[]
  adapter_matrix: string[]
  artifacts: ReleaseArtifact[]
}

export function discoverPaths(): { cliRoot: string, repoRoot: string } {
  const cliRoot = resolve(dirname(new URL(import.meta.url).pathname), "../..")
  const repoRoot = resolve(cliRoot, "..")
  return { cliRoot, repoRoot }
}

export function buildReleasePlan(targets: ReleaseTarget[], artifactsDir: string): ReleasePlan {
  const { cliRoot, repoRoot } = discoverPaths()
  const commands: string[] = []

  if (targets.includes("all") || targets.includes("cli")) {
    commands.push(`bun build src/index.ts --outfile ${join(artifactsDir, "loci")} --target bun --minify`)
  }
  if (targets.includes("all") || targets.includes("wasm-gc")) {
    commands.push("moon build --target wasm-gc --release --package zploc/loci/wasm_entry")
  }
  if (targets.includes("wasm")) {
    commands.push("moon build --target wasm --release --package zploc/loci/wasm_entry")
  }

  return {
    timestamp: new Date().toISOString(),
    cli_root: cliRoot,
    repo_root: repoRoot,
    artifacts_dir: artifactsDir,
    targets,
    engine_adapters: ["native", "wasm-shim"],
    commands,
  }
}

export async function runReleaseBuild(targets: ReleaseTarget[], artifactsDir: string): Promise<ReleaseManifest> {
  const plan = buildReleasePlan(targets, artifactsDir)
  await mkdir(artifactsDir, { recursive: true })

  const artifacts: ReleaseArtifact[] = []

  if (targets.includes("all") || targets.includes("cli")) {
    const outPath = join(artifactsDir, "loci")
    await runOrThrow(["bun", "build", "src/index.ts", "--outfile", outPath, "--target", "bun", "--minify"], plan.cli_root)
    artifacts.push({ kind: "bun-cli", path: outPath })
  }

  if (targets.includes("all") || targets.includes("wasm-gc")) {
    await runOrThrow(["moon", "build", "--target", "wasm-gc", "--release", "--package", "zploc/loci/wasm_entry"], plan.repo_root)

    const wasmFound = await findWasmEntryArtifact(plan.repo_root, "wasm-gc")
    if (wasmFound) {
      const outWasm = join(artifactsDir, "loci-entry.wasm")
      await Bun.write(outWasm, Bun.file(wasmFound))
      artifacts.push({ kind: "wasm", path: outWasm, note: `wasm-gc, copied from ${wasmFound}` })
    } else {
      artifacts.push({ kind: "wasm", path: "(not found)", note: "moon build wasm-gc succeeded but artifact not found in _build/" })
    }
  }

  if (targets.includes("wasm")) {
    await runOrThrow(["moon", "build", "--target", "wasm", "--release", "--package", "zploc/loci/wasm_entry"], plan.repo_root)

    const wasmFound = await findWasmEntryArtifact(plan.repo_root, "wasm")
    if (wasmFound) {
      const outWasm = join(artifactsDir, "loci-entry-wasm.wasm")
      await Bun.write(outWasm, Bun.file(wasmFound))
      artifacts.push({ kind: "wasm", path: outWasm, note: `wasm (linear-memory), copied from ${wasmFound}` })
    } else {
      artifacts.push({ kind: "wasm", path: "(not found)", note: "moon build wasm succeeded but artifact not found in _build/" })
    }
  }

  const manifest: ReleaseManifest = {
    generated_at: new Date().toISOString(),
    artifacts_dir: artifactsDir,
    targets,
    adapter_matrix: ["native", "wasm-shim"],
    artifacts,
  }

  const manifestPath = join(artifactsDir, "release-manifest.json")
  await Bun.write(manifestPath, JSON.stringify(manifest, null, 2) + "\n")

  return {
    ...manifest,
    artifacts: [...manifest.artifacts, { kind: "manifest", path: manifestPath }],
  }
}

async function runOrThrow(cmd: string[], cwd: string): Promise<void> {
  const proc = Bun.spawn(cmd, {
    cwd,
    stdout: "inherit",
    stderr: "inherit",
  })
  const code = await proc.exited
  if (code !== 0) {
    throw new Error(`Command failed (${code}): ${cmd.join(" ")}`)
  }
}

async function findWasmEntryArtifact(repoRoot: string, target: string = "wasm-gc"): Promise<string | null> {
  const candidateNames = ["wasm_entry.wasm", "entry.wasm"]
  // Moon builds always emit to _build/<target>/release/build/ (release mode)
  // or _build/<target>/debug/build/ (debug mode)
  const roots = [
    join(repoRoot, "_build", target, "release", "build"),
    join(repoRoot, "_build", target, "debug", "build"),
  ]

  for (const root of roots) {
    if (!await exists(root)) continue
    const found = await walkFind(root, candidateNames, 0, 6)
    if (found) return found
  }

  return null
}

async function walkFind(dir: string, names: string[], depth: number, maxDepth: number): Promise<string | null> {
  if (depth > maxDepth) return null
  const entries = await readdir(dir, { withFileTypes: true })

  for (const e of entries) {
    if (e.isFile() && names.includes(e.name)) {
      return join(dir, e.name)
    }
  }

  for (const e of entries) {
    if (!e.isDirectory()) continue
    if (e.name === "node_modules" || e.name === ".git") continue
    const nested = await walkFind(join(dir, e.name), names, depth + 1, maxDepth)
    if (nested) return nested
  }

  return null
}
