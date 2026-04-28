import { LociStore } from "../store.ts"
import { showWorkspaceStatus } from "../sdk/usecases/status.ts"

export async function cmdStatus(store: LociStore): Promise<void> {
  return showWorkspaceStatus(store)
}
