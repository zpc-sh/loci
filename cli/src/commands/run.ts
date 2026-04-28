import { resolve } from "path"
import { bootMulspAtDir } from "../sdk/ide/boot_mulsp.ts"

export async function cmdRun(args: string[]): Promise<void> {
  const dir = flag(args, "-f") ?? flag(args, "--from") ?? "."
  const reposRaw = flag(args, "--repos")
  const repos = reposRaw ? reposRaw.split(",").map(v => v.trim()).filter(Boolean) : null

  const result = await bootMulspAtDir({
    rootDir: resolve(dir),
    id: flag(args, "--id"),
    repos,
    title: flag(args, "--title"),
    specApi: flag(args, "--spec-api"),
    description: flag(args, "--desc"),
    message: flag(args, "--message"),
  })

  console.log(`mulsp booted in ${result.root_dir}`)
  console.log(`- nucleant: ${result.nucleant_id}`)
  console.log(`- nucleant file: ${result.nucleant_path}`)
  console.log(`- finger plan: ${result.finger_path}`)
  console.log(`- presented to: ${result.presented_to.length > 0 ? result.presented_to.join(", ") : "(none; no repos configured)"}`)
  console.log(`- locality: ${result.locality_report.locality}`)
  console.log(`- inertial diff: stable=${result.locality_report.stable_fields} changed=${result.locality_report.changed_fields} new=${result.locality_report.new_fields} inertia=${result.locality_report.inertia_percent}%`)
  console.log(`- dedup: ${result.locality_report.duplicate ? "hit" : "miss"}`)
}

function flag(args: string[], name: string): string | null {
  const i = args.indexOf(name)
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null
}
