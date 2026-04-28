import { LociStore } from "../store.ts"
import {
  enterLocus,
  signResidue,
  trailLocus,
  showLatestResidue,
  whereLoci,
} from "../sdk/usecases/genius.ts"

export async function cmdEnter(locusName: string, store: LociStore, args: string[]): Promise<void> {
  return enterLocus(locusName, store, args)
}

export async function cmdSign(store: LociStore, args: string[]): Promise<void> {
  return signResidue(store, args)
}

export async function cmdTrail(locusName: string, store: LociStore, args: string[]): Promise<void> {
  return trailLocus(locusName, store, args)
}

export async function cmdResidue(locusName: string, store: LociStore): Promise<void> {
  return showLatestResidue(locusName, store)
}

export async function cmdWhere(store: LociStore): Promise<void> {
  return whereLoci(store)
}
