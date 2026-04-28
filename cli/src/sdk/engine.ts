import { LociCore } from "../core.ts"

export type EngineKind = "native" | "wasm-shim"

export interface EngineAdapter {
  kind: EngineKind
  runPrint(args: string[]): Promise<number>
}

class NativeLociEngine implements EngineAdapter {
  readonly kind: EngineKind = "native"

  constructor(private readonly core: LociCore) {}

  async runPrint(args: string[]): Promise<number> {
    return this.core.runPrint(args)
  }
}

class WasmShimEngine implements EngineAdapter {
  readonly kind: EngineKind = "wasm-shim"

  constructor(private readonly shimBin: string, private readonly shimArgs: string[] = []) {}

  async runPrint(args: string[]): Promise<number> {
    const proc = Bun.spawn([this.shimBin, ...this.shimArgs, ...args], {
      stdout: "pipe",
      stderr: "pipe",
    })

    const [out, err, code] = await Promise.all([
      new Response(proc.stdout).text(),
      new Response(proc.stderr).text(),
      proc.exited,
    ])

    if (out) process.stdout.write(out)
    if (err) process.stderr.write(err)
    return code
  }
}

export function discoverEngineAdapter(preferred?: string | null): EngineAdapter {
  const selected = (preferred ?? process.env.LOCI_ENGINE ?? "native").toLowerCase()

  if (selected === "native") {
    return new NativeLociEngine(LociCore.discover())
  }

  if (selected === "wasm-shim") {
    const bin = process.env.LOCI_WASM_SHIM_BIN
    if (!bin) {
      throw new Error("LOCI_WASM_SHIM_BIN is required when LOCI_ENGINE=wasm-shim")
    }
    const argv = process.env.LOCI_WASM_SHIM_ARGS?.trim()
    const shimArgs = argv ? argv.split(/\s+/).filter(Boolean) : []
    return new WasmShimEngine(bin, shimArgs)
  }

  throw new Error(`Unknown LOCI_ENGINE '${selected}'. Use 'native' or 'wasm-shim'.`)
}
