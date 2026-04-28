import { mkdir, exists, stat } from "fs/promises"
import { join } from "path"
import { clack } from "../../tui.ts"
import { LociStore } from "../../store.ts"

export async function initWorkspace(store: LociStore): Promise<void> {
  const marker = join(store.lociRoot, ".loci")
  const markerConfig = join(marker, "config.json")

  clack.intro("loci init")

  if (await exists(markerConfig)) {
    clack.outro(`Already initialized at ${store.lociRoot}/`)
    return
  }
  if (await exists(marker)) {
    const info = await stat(marker)
    if (info.isFile()) {
      clack.outro(`Already initialized at ${store.lociRoot}/`)
      return
    }
  }

  await mkdir(store.lociRoot, { recursive: true })
  await store.initStore()

  if (await exists(marker)) {
    const info = await stat(marker)
    if (info.isFile()) {
      await Bun.write(marker, JSON.stringify({
        version: "0.1.0",
        storePath: store.storePath,
        created: new Date().toISOString(),
      }, null, 2))
    } else {
      await Bun.write(markerConfig, JSON.stringify({
        version: "0.1.0",
        storePath: store.storePath,
        created: new Date().toISOString(),
      }, null, 2))
    }
  } else {
    await Bun.write(marker, JSON.stringify({
      version: "0.1.0",
      storePath: store.storePath,
      created: new Date().toISOString(),
    }, null, 2))
  }

  clack.outro([
    "Initialized.",
    `  loci root: ${store.lociRoot}/`,
    `  store:     ${store.storePath}/`,
    "",
    "Next: loci loci new <name>",
  ].join("\n"))
}
