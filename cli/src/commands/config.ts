// loci config — repository configuration.

import { LociStore } from "../store.ts"
import { getConfig, setConfigValue } from "../vcs.ts"

export async function cmdConfig(store: LociStore, args: string[]): Promise<void> {
  const listFlag = args.includes("--list") || args.includes("-l")
  const positional = args.filter(a => !a.startsWith("-"))

  if (listFlag || positional.length === 0) {
    const cfg = await getConfig(store)
    const keys = Object.keys(cfg).sort()
    if (keys.length === 0) {
      console.log("No configuration set.")
      return
    }
    for (const k of keys) {
      console.log(`${k}=${cfg[k]}`)
    }
    return
  }

  if (positional.length === 1) {
    // Get value
    const cfg = await getConfig(store)
    const val = cfg[positional[0]]
    if (val !== undefined) {
      console.log(val)
    } else {
      process.exit(1)
    }
    return
  }

  // Set value
  await setConfigValue(store, positional[0], positional[1])
  console.log(`Set ${positional[0]} = ${positional[1]}`)
}
