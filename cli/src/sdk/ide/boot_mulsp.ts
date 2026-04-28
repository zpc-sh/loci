import { mkdir, exists, readdir, appendFile } from "fs/promises"
import { basename, join, resolve } from "path"
import { buildFingerPlanContent, type NucleantRecord, type NucleantRepoState } from "./finger.ts"
import { loadIdeConfig } from "./repos.ts"

interface CodexMessage {
  id: string
  timestamp: string
  from_repo: string
  to_repo: string
  thread: string
  message: string
}

export interface BootMulspOptions {
  rootDir: string
  id?: string | null
  repos?: string[] | null
  title?: string | null
  specApi?: string | null
  description?: string | null
  message?: string | null
}

export interface BootMulspResult {
  root_dir: string
  nucleant_id: string
  nucleant_path: string
  finger_path: string
  presented_to: string[]
  locality_report: LocalityIngestReport
}

interface LocalityState {
  locality: string
  signatures: Record<string, string>
  field_values: Record<string, string>
  locality_ingests: number
  locality_dedup_hits: number
  updated_at: string
}

export interface LocalityIngestReport {
  locality: string
  field_total: number
  stable_fields: number
  changed_fields: number
  new_fields: number
  duplicate: boolean
  inertia_percent: number
  prior_signature: string
  current_signature: string
}

export async function bootMulspAtDir(opts: BootMulspOptions): Promise<BootMulspResult> {
  const rootDir = resolve(opts.rootDir)
  const ideRoot = join(rootDir, ".loci", "ide")
  const nucleantsDir = join(ideRoot, "nucleants")
  const fingerDir = join(ideRoot, "finger")
  const fsmLocalityDir = join(ideRoot, "fsm-locality")
  const reposFile = join(ideRoot, "repos.json")

  const now = new Date().toISOString()
  const id = opts.id?.trim() || defaultMulspNucleantId(rootDir)
  const thread = `nucleant-${id}`
  const title = opts.title?.trim() || "codex-locus mulsp bootstrap"
  const specApi = opts.specApi?.trim() || "docs/MULSP_SPEC.md"
  const description = opts.description?.trim() || "spawn mulsp packet, bind codex locus, emit finger.plan for cross-repo pickup"

  await mkdir(nucleantsDir, { recursive: true })
  await mkdir(fingerDir, { recursive: true })
  await mkdir(fsmLocalityDir, { recursive: true })

  const nucleantPath = join(nucleantsDir, `${id}.json`)
  const existing = await loadNucleant(nucleantPath)

  let record: NucleantRecord = existing ?? {
    id,
    title,
    spec_api: specApi,
    description,
    created_at: now,
    updated_at: now,
    presented_to: [],
  }

  const repoConfig = await loadIdeConfig(reposFile)
  const targets = resolveTargets(repoConfig.repos, opts.repos)
  const fromRepo = basename(rootDir)
  const fanoutMessage = opts.message?.trim() || "pickup from ./loci/chatgpt"

  const presented: string[] = []
  for (const target of targets) {
    const body = [
      `[NUCLEANT:${id}] ${record.title}`,
      `spec_api=${record.spec_api}`,
      `finger_plan_ref=${join(fingerDir, `${id}.finger.plan`)}`,
      `description=${record.description || "(none)"}`,
      fanoutMessage ? `note=${fanoutMessage}` : "",
    ].filter(Boolean).join("\n")

    const entry: CodexMessage = {
      id: crypto.randomUUID(),
      timestamp: now,
      from_repo: fromRepo,
      to_repo: target.name,
      thread,
      message: body,
    }

    await appendCodexMessage(target.path, thread, entry)
    await appendLocalOutbox(rootDir, thread, entry)
    presented.push(target.name)

    const state: NucleantRepoState = {
      repo: target.name,
      thread,
      status: "presented",
      last_update: now,
      note: fanoutMessage || null,
    }
    record = upsertNucleantState(record, state)
  }

  record = { ...record, updated_at: now }
  await Bun.write(nucleantPath, JSON.stringify(record, null, 2))

  const fingerPath = join(fingerDir, `${id}.finger.plan`)
  const fingerContent = buildFingerPlanContent(record)
  await Bun.write(fingerPath, fingerContent)
  const semanticFingerInput = [
    `id=${record.id}`,
    `title=${record.title}`,
    `spec_api=${record.spec_api}`,
    `description=${record.description}`,
    `presented_to=${presented.slice().sort().join(",")}`,
  ].join("|")

  const locality = `run.mulsp::${rootDir}`
  let localityReport = await ingestLocalityPattern(
    fsmLocalityDir,
    locality,
    [
      ["pattern.kind", "mulsp.boot"],
      ["pattern.id", record.id],
      ["pattern.spec_api", record.spec_api],
      ["pattern.presented_to", presented.slice().sort().join(",")],
      ["pattern.finger_hash", await digestHex(semanticFingerInput)],
    ],
  )
  await appendLocalityReport(fsmLocalityDir, locality, localityReport)

  return {
    root_dir: rootDir,
    nucleant_id: id,
    nucleant_path: nucleantPath,
    finger_path: fingerPath,
    presented_to: presented,
    locality_report: localityReport,
  }
}

function defaultMulspNucleantId(rootDir: string): string {
  const name = basename(rootDir).replace(/[^a-zA-Z0-9_-]/g, "-") || "loci"
  return `N-${name}-mulsp-v1`
}

async function loadNucleant(path: string): Promise<NucleantRecord | null> {
  if (!await exists(path)) return null
  try {
    return JSON.parse(await Bun.file(path).text()) as NucleantRecord
  } catch {
    return null
  }
}

function resolveTargets(all: Array<{ name: string, path: string }>, requested: string[] | null | undefined): Array<{ name: string, path: string }> {
  if (!requested || requested.length === 0 || requested.includes("all")) return all
  return all.filter(r => requested.includes(r.name))
}

function upsertNucleantState(record: NucleantRecord, state: NucleantRepoState): NucleantRecord {
  const kept = record.presented_to.filter(s => s.repo !== state.repo)
  return {
    ...record,
    presented_to: [...kept, state].sort((a, b) => a.repo.localeCompare(b.repo)),
  }
}

async function appendCodexMessage(repoPath: string, thread: string, message: CodexMessage): Promise<void> {
  const dir = join(repoPath, ".loci", "ide", "codex-dropbox")
  await mkdir(dir, { recursive: true })
  const path = join(dir, `${thread}.jsonl`)
  await appendFile(path, JSON.stringify(message) + "\n")
}

async function appendLocalOutbox(rootDir: string, thread: string, message: CodexMessage): Promise<void> {
  const dir = join(rootDir, ".loci", "ide", "codex-outbox")
  await mkdir(dir, { recursive: true })
  const path = join(dir, `${thread}.jsonl`)
  await appendFile(path, JSON.stringify(message) + "\n")
}

export async function listNucleantIdsAtDir(rootDir: string): Promise<string[]> {
  const dir = join(resolve(rootDir), ".loci", "ide", "nucleants")
  if (!await exists(dir)) return []
  const files = (await readdir(dir)).filter(f => f.endsWith(".json")).sort()
  return files.map(f => f.replace(/\.json$/, ""))
}

function sanitizeCanonical(value: string): string {
  const out = value
    .replace(/\u200B/g, "")
    .replace(/\u200C/g, "")
    .replace(/\uFEFF/g, "")
    .replace(/[\u202A-\u202E\u2066-\u2069]/g, "")
    .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, "")
    .replace(/\r\n|\r|\n/g, "_")
    .replace(/,/g, ";")
  return out === "" ? "none" : out
}

function fieldRef(locality: string, key: string): string {
  return `${locality}::${key}`
}

function signatureFromFields(fields: Array<[string, string]>): string {
  const sig = fields
    .map(([k, v]) => `${sanitizeCanonical(k)}=${sanitizeCanonical(v)}`)
    .sort()
  return sig.length > 0 ? sig.join("|") : "none"
}

async function ingestLocalityPattern(
  fsmLocalityDir: string,
  locality: string,
  fields: Array<[string, string]>,
): Promise<LocalityIngestReport> {
  const statePath = join(fsmLocalityDir, `${safeSlug(locality)}.state.json`)
  const state = await loadLocalityState(statePath, locality)

  let stable_fields = 0
  let changed_fields = 0
  let new_fields = 0

  for (const [rawKey, rawValue] of fields) {
    const key = sanitizeCanonical(rawKey)
    const value = sanitizeCanonical(rawValue)
    const ref = fieldRef(locality, key)
    const prev = state.field_values[ref]
    if (prev === undefined) {
      new_fields += 1
    } else if (prev === value) {
      stable_fields += 1
    } else {
      changed_fields += 1
    }
    state.field_values[ref] = value
  }

  const current_signature = signatureFromFields(fields)
  const prior_signature = state.signatures[locality] ?? "none"
  const duplicate = current_signature === prior_signature
  const field_total = fields.length
  const inertia_percent = field_total === 0 ? 100 : Math.floor((stable_fields * 100) / field_total)

  state.signatures[locality] = current_signature
  state.locality_ingests += 1
  if (duplicate) state.locality_dedup_hits += 1
  state.updated_at = new Date().toISOString()
  await Bun.write(statePath, JSON.stringify(state, null, 2) + "\n")

  return {
    locality,
    field_total,
    stable_fields,
    changed_fields,
    new_fields,
    duplicate,
    inertia_percent,
    prior_signature,
    current_signature,
  }
}

async function loadLocalityState(path: string, locality: string): Promise<LocalityState> {
  if (await exists(path)) {
    try {
      return JSON.parse(await Bun.file(path).text()) as LocalityState
    } catch {
      // fall through to new state
    }
  }
  return {
    locality,
    signatures: {},
    field_values: {},
    locality_ingests: 0,
    locality_dedup_hits: 0,
    updated_at: new Date().toISOString(),
  }
}

async function appendLocalityReport(
  fsmLocalityDir: string,
  locality: string,
  report: LocalityIngestReport,
): Promise<void> {
  const path = join(fsmLocalityDir, `${safeSlug(locality)}.jsonl`)
  await appendFile(path, JSON.stringify({ timestamp: new Date().toISOString(), ...report }) + "\n")
}

function safeSlug(value: string): string {
  return value.replace(/[^a-zA-Z0-9_.-]/g, "_")
}

async function digestHex(value: string): Promise<string> {
  const hasher = new Bun.CryptoHasher("sha256")
  hasher.update(value)
  return hasher.digest("hex")
}
