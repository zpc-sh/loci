import { LociStore } from "../store.ts"
import { createLocus, listLociWithLastSession } from "../sdk/usecases/locus.ts"

export async function cmdLocusNew(store: LociStore, args: string[]): Promise<void> {
  return createLocus(store, args)
}

export async function cmdLocusLs(store: LociStore): Promise<void> {
  return listLociWithLastSession(store)
}
