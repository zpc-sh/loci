import { mkdir } from "fs/promises"
import { dirname, resolve } from "path"

export interface NucleantRepoState {
  repo: string
  thread: string
  status: "presented" | "in_progress" | "resolved"
  last_update: string
  note: string | null
}

export interface NucleantRecord {
  id: string
  title: string
  spec_api: string
  description: string
  created_at: string
  updated_at: string
  presented_to: NucleantRepoState[]
}

export function buildFingerPlanContent(record: NucleantRecord): string {
  const lines: string[] = [
    "kind: merkin.yata.plan",
    "track=program",
    "mode=compact",
    "generator=loci.ide",
    `note=nucleant:${record.id}`,
    "self_report=1",
    "self_report_overlay=codex",
    "self_report_view=nucleant",
    `nucleant_id=${record.id}`,
    `nucleant_title=${record.title}`,
    `spec_api=${record.spec_api}`,
    `created_at=${record.created_at}`,
    `updated_at=${record.updated_at}`,
    `self_report_gap=${record.presented_to.length}`,
  ]
  for (const state of record.presented_to) {
    const note = state.note ? state.note.replace(/\s+/g, "_") : "none"
    lines.push(
      `- N-${record.id} repo=${state.repo} status=${state.status} thread=${state.thread} updated=${state.last_update} note=${note}`,
    )
  }
  return lines.join("\n") + "\n"
}

export async function emitFingerPlan(
  id: string,
  record: NucleantRecord,
  outPath: string | null,
  defaultPath: string,
  defaultDir: string,
): Promise<{ id: string, path: string, content: string }> {
  const content = buildFingerPlanContent(record)
  const path = outPath ? resolve(outPath) : defaultPath
  await mkdir(outPath ? dirname(path) : defaultDir, { recursive: true })
  await Bun.write(path, content)
  return { id, path, content }
}
