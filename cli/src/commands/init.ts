import { LociStore } from "../store.ts"
import { initWorkspace } from "../sdk/usecases/init.ts"

export async function cmdInit(store: LociStore, _args: string[]): Promise<void> {
  return initWorkspace(store)
}
