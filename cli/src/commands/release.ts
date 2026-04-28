import { join, resolve } from "path"
import { buildReleasePlan, runReleaseBuild, type ReleaseTarget } from "../release/pipeline.ts"

export async function cmdRelease(args: string[]): Promise<void> {
  const sub = args[0] ?? "plan"
  const rest = args.slice(1)

  switch (sub) {
    case "plan": {
      const targets = parseTargets(rest)
      const artifacts = parseArtifactsDir(rest)
      const plan = buildReleasePlan(targets, artifacts)
      console.log(JSON.stringify(plan, null, 2))
      return
    }

    case "build": {
      const targets = parseTargets(rest)
      const artifacts = parseArtifactsDir(rest)
      const manifest = await runReleaseBuild(targets, artifacts)
      console.log(`release build complete: ${manifest.artifacts_dir}`)
      for (const artifact of manifest.artifacts) {
        const note = artifact.note ? ` (${artifact.note})` : ""
        console.log(`- ${artifact.kind.padEnd(8)} ${artifact.path}${note}`)
      }
      return
    }

    case "help":
    case "--help":
    case "-h":
      usage()
      return

    default:
      console.error(`Unknown release subcommand: ${sub}`)
      usage()
      process.exit(1)
  }
}

function usage(): void {
  console.log(`
loci release — release pipeline for sdk/runtime artifacts

USAGE
  loci release plan [--target all|cli|wasm-gc|wasm] [--artifacts-dir <path>]
  loci release build [--target all|cli|wasm-gc|wasm] [--artifacts-dir <path>]

OPTIONS
  --target <value>          Build target (default: all → cli + wasm-gc)
  --artifacts-dir <path>    Output directory (default: ../artifacts)
`.trim())
}

function parseTargets(args: string[]): ReleaseTarget[] {
  const raw = (flag(args, "--target") ?? "all").trim().toLowerCase()
  switch (raw) {
    case "all":
    case "cli":
    case "wasm":
    case "wasm-gc":
      return [raw as ReleaseTarget]
    default:
      console.error(`Invalid --target '${raw}'. Use all|cli|wasm|wasm-gc`)
      process.exit(1)
  }
}

function parseArtifactsDir(args: string[]): string {
  const raw = flag(args, "--artifacts-dir")
  if (raw) return resolve(raw)
  return resolve(join(process.cwd(), "..", "artifacts"))
}

function flag(args: string[], name: string): string | null {
  const i = args.indexOf(name)
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null
}
