import { mkdir, readdir, exists, appendFile } from "fs/promises"
import { join, resolve, basename, dirname } from "path"
import { randomBytes } from "crypto"
import { createInterface } from "readline"

interface RepoEntry {
  name: string
  path: string
}

interface IdeConfig {
  repos: RepoEntry[]
}

interface CodexMessage {
  id: string
  timestamp: string
  from_repo: string
  to_repo: string
  thread: string
  message: string
}

interface SearchHit {
  repo: string
  file: string
  line: number
  text: string
  score: number
}

type NucleantStatus = "presented" | "in_progress" | "resolved"

interface NucleantRepoState {
  repo: string
  thread: string
  status: NucleantStatus
  last_update: string
  note: string | null
}

interface NucleantRecord {
  id: string
  title: string
  spec_api: string
  description: string
  created_at: string
  updated_at: string
  presented_to: NucleantRepoState[]
}

type SocketProtocol = "loci" | "mcp" | "lsp"

interface SocketRequest {
  id: string | number | null
  protocol?: SocketProtocol
  method: string
  params?: unknown
}

interface SocketResponse {
  id: string | number | null
  ok: boolean
  result?: unknown
  error?: {
    code: string
    message: string
  }
}

const IDE_ROOT = ".loci/ide"
const IDE_REPOS_FILE = join(IDE_ROOT, "repos.json")
const IDE_NUCLEANTS_DIR = join(IDE_ROOT, "nucleants")
const IDE_FINGER_DIR = join(IDE_ROOT, "finger")

export async function cmdIde(args: string[]): Promise<void> {
  const sub = args[0]
  const rest = args.slice(1)
  switch (sub) {
    case "repo":
      return cmdIdeRepo(rest)
    case "search":
      return cmdIdeSearch(rest)
    case "ask":
      return cmdIdeAsk(rest)
    case "inbox":
      return cmdIdeInbox(rest)
    case "nucleant":
      return cmdIdeNucleant(rest)
    case "finger":
      return cmdIdeFinger(rest)
    case "serve":
      return cmdIdeServe(rest)
    case "help":
    case "--help":
    case "-h":
    case undefined:
      return ideUsage()
    default:
      console.error(`Unknown ide subcommand: ${sub}`)
      ideUsage()
      process.exit(1)
  }
}

async function cmdIdeNucleant(args: string[]): Promise<void> {
  const sub = args[0]
  const rest = args.slice(1)
  switch (sub) {
    case "new":
      return cmdNucleantNew(rest)
    case "present":
      return cmdNucleantPresent(rest)
    case "mark":
      return cmdNucleantMark(rest)
    case "status":
    case undefined:
      return cmdNucleantStatus(rest)
    default:
      console.error(`Unknown ide nucleant subcommand: ${sub}`)
      console.error("Usage: loci ide nucleant [new|present|mark|status] ...")
      process.exit(1)
  }
}

async function cmdIdeServe(args: string[]): Promise<void> {
  if (args.includes("--help") || args.includes("-h")) {
    console.log("Usage: loci ide serve [--stdio]")
    return
  }
  const rl = createInterface({
    input: process.stdin,
    output: process.stdout,
    terminal: false,
  })
  for await (const raw of rl) {
    const line = raw.trim()
    if (!line) continue
    let parsed: unknown
    try {
      parsed = JSON.parse(line)
    } catch {
      const response: SocketResponse = {
        id: null,
        ok: false,
        error: { code: "INVALID_JSON", message: "input line is not valid JSON" },
      }
      process.stdout.write(JSON.stringify(response) + "\n")
      continue
    }
    const response = await handleSocketRequest(parsed)
    process.stdout.write(JSON.stringify(response) + "\n")
  }
}

async function cmdIdeFinger(args: string[]): Promise<void> {
  const sub = args[0]
  const rest = args.slice(1)
  if (sub === "plan") {
    const id = rest[0]
    if (!id) {
      console.error("Usage: loci ide finger plan <nucleant-id> [--out <path>]")
      process.exit(1)
    }
    const out = flag(rest, "--out")
    const result = await apiFingerPlan(id, out)
    console.log(`finger.plan updated: ${result.path}`)
    return
  }
  console.error(`Unknown ide finger subcommand: ${sub}`)
  console.error("Usage: loci ide finger plan <nucleant-id> [--out <path>]")
  process.exit(1)
}

async function cmdIdeRepo(args: string[]): Promise<void> {
  const sub = args[0]
  const rest = args.slice(1)
  switch (sub) {
    case "add": {
      const name = rest[0]
      const pathArg = rest[1]
      if (!name || !pathArg) {
        console.error("Usage: loci ide repo add <name> <path>")
        process.exit(1)
      }
      const absPath = resolve(pathArg)
      const config = await loadIdeConfig()
      const filtered = config.repos.filter(r => r.name !== name && r.path !== absPath)
      filtered.push({ name, path: absPath })
      await saveIdeConfig({ repos: filtered.sort((a, b) => a.name.localeCompare(b.name)) })
      console.log(`Added repo '${name}' => ${absPath}`)
      return
    }
    case "ls":
    case undefined: {
      const config = await loadIdeConfig()
      if (config.repos.length === 0) {
        console.log("No IDE repos configured. Add one with: loci ide repo add <name> <path>")
        return
      }
      for (const repo of config.repos) {
        console.log(`${repo.name.padEnd(16)} ${repo.path}`)
      }
      return
    }
    default:
      console.error(`Unknown ide repo subcommand: ${sub}`)
      console.error("Usage: loci ide repo [add|ls] ...")
      process.exit(1)
  }
}

async function cmdIdeSearch(args: string[]): Promise<void> {
  const query = positionalJoin(args)
  if (!query) {
    console.error("Usage: loci ide search <query> [--repo <name|all>] [--limit <n>]")
    process.exit(1)
  }
  const repoFilter = flag(args, "--repo") ?? "all"
  const limit = parseInt(flag(args, "--limit") ?? "20", 10)
  const targets = await resolveSearchTargets(repoFilter)

  const hits: SearchHit[] = []
  for (const repo of targets) {
    const repoHits = await runRepoSearch(repo.name, repo.path, query, limit * 2)
    hits.push(...repoHits)
  }
  hits.sort((a, b) => b.score - a.score)

  const finalHits = hits.slice(0, Math.max(1, limit))
  if (finalHits.length === 0) {
    console.log("No matches.")
    return
  }
  for (const hit of finalHits) {
    console.log(`[${hit.repo}] ${hit.file}:${hit.line}  score=${hit.score}`)
    console.log(`  ${hit.text}`)
  }
}

async function cmdIdeAsk(args: string[]): Promise<void> {
  const repoName = args[0]
  const message = positionalJoin(args.slice(1))
  if (!repoName || !message) {
    console.error("Usage: loci ide ask <repo> <message> [--thread <id>] [--from <repo-name>]")
    process.exit(1)
  }
  const config = await loadIdeConfig()
  const target = config.repos.find(r => r.name === repoName)
  if (!target) {
    console.error(`Unknown repo '${repoName}'. Add it first: loci ide repo add ${repoName} <path>`)
    process.exit(1)
  }
  const thread = flag(args, "--thread") ?? newThreadId()
  const fromRepo = flag(args, "--from") ?? basename(process.cwd())
  const entry: CodexMessage = {
    id: randomBytes(6).toString("hex"),
    timestamp: new Date().toISOString(),
    from_repo: fromRepo,
    to_repo: repoName,
    thread,
    message,
  }

  await appendCodexMessage(target.path, thread, entry)
  await appendLocalOutbox(thread, entry)
  console.log(`sent -> ${repoName}  thread=${thread}`)
}

async function cmdIdeInbox(args: string[]): Promise<void> {
  const repoName = flag(args, "--repo")
  const threadFilter = flag(args, "--thread")
  const limit = parseInt(flag(args, "--limit") ?? "20", 10)
  const repoPath = await resolveInboxRepoPath(repoName)
  const messages = await readCodexMessages(repoPath, threadFilter)
  if (messages.length === 0) {
    console.log("No inbox messages.")
    return
  }
  const finalMsgs = messages.slice(-Math.max(1, limit))
  for (const msg of finalMsgs) {
    console.log(`${msg.timestamp} [${msg.thread}] ${msg.from_repo} -> ${msg.to_repo}`)
    console.log(`  ${msg.message}`)
  }
}

async function cmdNucleantNew(args: string[]): Promise<void> {
  const id = args[0]
  if (!id) {
    console.error("Usage: loci ide nucleant new <id> --title <title> --spec-api <ref> [--desc <text>]")
    process.exit(1)
  }
  const title = flag(args, "--title") ?? id
  const specApi = flag(args, "--spec-api")
  if (!specApi) {
    console.error("Missing --spec-api <ref>")
    process.exit(1)
  }
  const description = flag(args, "--desc") ?? ""
  const now = new Date().toISOString()
  const record: NucleantRecord = {
    id,
    title,
    spec_api: specApi,
    description,
    created_at: now,
    updated_at: now,
    presented_to: [],
  }
  await saveNucleant(record)
  await saveFingerPlan(record)
  console.log(`nucleant created: ${id}`)
}

async function cmdNucleantPresent(args: string[]): Promise<void> {
  const id = args[0]
  if (!id) {
    console.error("Usage: loci ide nucleant present <id> [--repos <r1,r2|all>] [--message <text>]")
    process.exit(1)
  }
  const existing = await loadNucleant(id)
  if (!existing) {
    console.error(`Nucleant '${id}' not found. Create it with: loci ide nucleant new ${id} ...`)
    process.exit(1)
  }
  const config = await loadIdeConfig()
  const reposRaw = flag(args, "--repos") ?? "all"
  const targets = reposRaw === "all"
    ? config.repos
    : config.repos.filter(r => reposRaw.split(",").map(v => v.trim()).includes(r.name))
  if (targets.length === 0) {
    console.error("No target repos resolved. Add repos via `loci ide repo add ...`.")
    process.exit(1)
  }

  const thread = `nucleant-${id}`
  const extra = flag(args, "--message") ?? ""
  const fromRepo = basename(process.cwd())
  const now = new Date().toISOString()
  let record = existing
  for (const target of targets) {
    const msg: CodexMessage = {
      id: randomBytes(6).toString("hex"),
      timestamp: now,
      from_repo: fromRepo,
      to_repo: target.name,
      thread,
      message: [
        `[NUCLEANT:${id}] ${record.title}`,
        `spec_api=${record.spec_api}`,
        `finger_plan_ref=${fingerPlanPath(id)}`,
        `description=${record.description || "(none)"}`,
        extra ? `note=${extra}` : "",
      ].filter(Boolean).join("\n"),
    }
    await appendCodexMessage(target.path, thread, msg)
    await appendLocalOutbox(thread, msg)
    record = upsertNucleantState(record, {
      repo: target.name,
      thread,
      status: "presented",
      last_update: now,
      note: extra || null,
    })
  }
  await saveNucleant(record)
  await saveFingerPlan(record)
  console.log(`nucleant presented: ${id} -> ${targets.map(t => t.name).join(", ")}`)
}

async function cmdNucleantMark(args: string[]): Promise<void> {
  const id = args[0]
  if (!id) {
    console.error("Usage: loci ide nucleant mark <id> --repo <name> --status <presented|in_progress|resolved> [--note <text>]")
    process.exit(1)
  }
  const repo = flag(args, "--repo")
  const statusRaw = flag(args, "--status")
  if (!repo || !statusRaw) {
    console.error("Missing --repo or --status")
    process.exit(1)
  }
  const status = parseNucleantStatus(statusRaw)
  if (!status) {
    console.error("Invalid --status. Use presented|in_progress|resolved")
    process.exit(1)
  }
  const existing = await loadNucleant(id)
  if (!existing) {
    console.error(`Nucleant '${id}' not found.`)
    process.exit(1)
  }
  const note = flag(args, "--note")
  const record = upsertNucleantState(existing, {
    repo,
    thread: `nucleant-${id}`,
    status,
    last_update: new Date().toISOString(),
    note: note ?? null,
  })
  await saveNucleant(record)
  await saveFingerPlan(record)
  console.log(`nucleant ${id}: ${repo} -> ${status}`)
}

async function cmdNucleantStatus(args: string[]): Promise<void> {
  const id = args[0]
  if (!id) {
    const ids = await listNucleantIds()
    if (ids.length === 0) {
      console.log("No nucleants found. Create one with: loci ide nucleant new <id> ...")
      return
    }
    for (const item of ids) console.log(item)
    return
  }
  const record = await loadNucleant(id)
  if (!record) {
    console.error(`Nucleant '${id}' not found.`)
    process.exit(1)
  }
  console.log(`id: ${record.id}`)
  console.log(`title: ${record.title}`)
  console.log(`spec_api: ${record.spec_api}`)
  if (record.description) console.log(`description: ${record.description}`)
  console.log(`updated: ${record.updated_at}`)
  if (record.presented_to.length === 0) {
    console.log("presented_to: (none)")
    return
  }
  const resolved = record.presented_to.filter(s => s.status === "resolved").length
  const inProgress = record.presented_to.filter(s => s.status === "in_progress").length
  const presented = record.presented_to.filter(s => s.status === "presented").length
  const total = record.presented_to.length
  console.log(`compliance: resolved=${resolved}/${total} in_progress=${inProgress} presented=${presented}`)
  console.log("presented_to:")
  for (const s of record.presented_to) {
    console.log(`  - ${s.repo}  status=${s.status}  thread=${s.thread}  updated=${s.last_update}`)
    if (s.note) console.log(`    note: ${s.note}`)
  }
}

async function handleSocketRequest(raw: unknown): Promise<SocketResponse> {
  const req = parseSocketRequest(raw)
  if (!req.ok) {
    return {
      id: null,
      ok: false,
      error: { code: "INVALID_REQUEST", message: req.error },
    }
  }
  try {
    const request = req.value
    const protocol = request.protocol ?? "loci"
    let result: unknown
    if (protocol === "loci") {
      result = await handleLociMethod(request.method, request.params)
    } else if (protocol === "mcp") {
      result = await handleMcpMethod(request.method, request.params)
    } else {
      result = await handleLspMethod(request.method, request.params)
    }
    return { id: request.id, ok: true, result }
  } catch (error) {
    return {
      id: req.value.id,
      ok: false,
      error: {
        code: "METHOD_ERROR",
        message: error instanceof Error ? error.message : "request failed",
      },
    }
  }
}

function parseSocketRequest(raw: unknown): { ok: true, value: SocketRequest } | { ok: false, error: string } {
  if (!raw || typeof raw !== "object") return { ok: false, error: "request must be an object" }
  const rec = raw as Record<string, unknown>
  const method = rec.method
  if (typeof method !== "string" || method.length === 0) {
    return { ok: false, error: "missing string method" }
  }
  const protocolRaw = rec.protocol
  let protocol: SocketProtocol | undefined = undefined
  if (typeof protocolRaw === "string") {
    if (protocolRaw === "loci" || protocolRaw === "mcp" || protocolRaw === "lsp") {
      protocol = protocolRaw
    } else {
      return { ok: false, error: "protocol must be one of loci|mcp|lsp" }
    }
  }
  const idRaw = rec.id
  const id = (typeof idRaw === "string" || typeof idRaw === "number" || idRaw === null)
    ? idRaw
    : null
  return {
    ok: true,
    value: {
      id,
      protocol,
      method,
      params: rec.params,
    },
  }
}

async function handleLociMethod(method: string, params: unknown): Promise<unknown> {
  switch (method) {
    case "ide.ping":
      return { pong: true, now: new Date().toISOString() }
    case "ide.repo.list":
      return apiRepoList()
    case "ide.repo.add": {
      const p = asRecord(params)
      const name = requireString(p, "name")
      const path = requireString(p, "path")
      return apiRepoAdd(name, path)
    }
    case "ide.search": {
      const p = asRecord(params)
      const query = requireString(p, "query")
      const repo = optionalString(p, "repo") ?? "all"
      const limit = optionalNumber(p, "limit") ?? 20
      return apiSearch(query, repo, limit)
    }
    case "ide.ask": {
      const p = asRecord(params)
      const repo = requireString(p, "repo")
      const message = requireString(p, "message")
      const thread = optionalString(p, "thread")
      const from = optionalString(p, "from")
      return apiAsk(repo, message, thread, from)
    }
    case "ide.inbox": {
      const p = asRecord(params)
      const repo = optionalString(p, "repo")
      const thread = optionalString(p, "thread")
      const limit = optionalNumber(p, "limit") ?? 20
      return apiInbox(repo, thread, limit)
    }
    case "ide.nucleant.new": {
      const p = asRecord(params)
      const id = requireString(p, "id")
      const title = optionalString(p, "title") ?? id
      const specApi = requireString(p, "spec_api")
      const description = optionalString(p, "description") ?? ""
      return apiNucleantNew(id, title, specApi, description)
    }
    case "ide.nucleant.present": {
      const p = asRecord(params)
      const id = requireString(p, "id")
      const repos = optionalStringArray(p, "repos")
      const message = optionalString(p, "message") ?? ""
      return apiNucleantPresent(id, repos, message)
    }
    case "ide.nucleant.mark": {
      const p = asRecord(params)
      const id = requireString(p, "id")
      const repo = requireString(p, "repo")
      const status = requireString(p, "status")
      const note = optionalString(p, "note")
      return apiNucleantMark(id, repo, status, note)
    }
    case "ide.nucleant.status": {
      const p = asRecord(params)
      const id = optionalString(p, "id")
      return apiNucleantStatus(id)
    }
    case "ide.finger.plan": {
      const p = asRecord(params)
      const id = requireString(p, "id")
      const out = optionalString(p, "out")
      return apiFingerPlan(id, out)
    }
    default:
      throw new Error(`unknown loci method: ${method}`)
  }
}

async function handleMcpMethod(method: string, params: unknown): Promise<unknown> {
  if (method === "tools/list") {
    return {
      tools: [
        { name: "ide.search", description: "Cross-repo semantic search" },
        { name: "ide.ask", description: "Send codex message to repo dropbox" },
        { name: "ide.inbox", description: "Read codex dropbox messages" },
        { name: "ide.nucleant.present", description: "Fan out nucleant to repos" },
        { name: "ide.nucleant.status", description: "Read nucleant convergence state" },
        { name: "ide.finger.plan", description: "Emit/update first-class finger.plan for nucleant" },
      ],
    }
  }
  if (method === "tools/call") {
    const p = asRecord(params)
    const name = requireString(p, "name")
    const args = asRecord(p.arguments)
    return handleLociMethod(name, args)
  }
  throw new Error(`unknown mcp method: ${method}`)
}

async function handleLspMethod(method: string, params: unknown): Promise<unknown> {
  if (method === "initialize") {
    return {
      capabilities: {
        executeCommandProvider: {
          commands: [
            "loci.ide.search",
            "loci.ide.ask",
            "loci.ide.nucleant.present",
            "loci.ide.nucleant.status",
            "loci.ide.finger.plan",
          ],
        },
        workspaceSymbolProvider: true,
      },
    }
  }
  if (method === "shutdown") return null
  if (method === "workspace/symbol") {
    const p = asRecord(params)
    const query = requireString(p, "query")
    const hits = await apiSearch(query, "all", 25)
    return hits.map(hit => ({
      name: `${hit.repo}:${hit.file}:${hit.line}`,
      kind: 13,
      location: {
        uri: `file://${resolve(hit.repo, hit.file)}`,
      },
      detail: hit.text,
    }))
  }
  if (method === "workspace/executeCommand") {
    const p = asRecord(params)
    const command = requireString(p, "command")
    const args = Array.isArray(p.arguments) ? p.arguments : []
    if (command === "loci.ide.search") {
      const query = typeof args[0] === "string" ? args[0] : ""
      return apiSearch(query, "all", 20)
    }
    if (command === "loci.ide.nucleant.status") {
      const id = typeof args[0] === "string" ? args[0] : undefined
      return apiNucleantStatus(id)
    }
    if (command === "loci.ide.finger.plan") {
      const id = typeof args[0] === "string" ? args[0] : ""
      const out = typeof args[1] === "string" ? args[1] : null
      return apiFingerPlan(id, out)
    }
    throw new Error(`unknown lsp command: ${command}`)
  }
  throw new Error(`unknown lsp method: ${method}`)
}

function asRecord(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object") return {}
  return value as Record<string, unknown>
}

function requireString(record: Record<string, unknown>, key: string): string {
  const value = record[key]
  if (typeof value !== "string" || value.length === 0) {
    throw new Error(`missing string field: ${key}`)
  }
  return value
}

function optionalString(record: Record<string, unknown>, key: string): string | null {
  const value = record[key]
  return typeof value === "string" && value.length > 0 ? value : null
}

function optionalNumber(record: Record<string, unknown>, key: string): number | null {
  const value = record[key]
  if (typeof value === "number" && Number.isFinite(value)) return value
  return null
}

function optionalStringArray(record: Record<string, unknown>, key: string): string[] | null {
  const value = record[key]
  if (!Array.isArray(value)) return null
  const out = value.filter(v => typeof v === "string").map(v => String(v).trim()).filter(Boolean)
  return out.length > 0 ? out : null
}

async function resolveSearchTargets(repoFilter: string): Promise<RepoEntry[]> {
  const config = await loadIdeConfig()
  if (repoFilter === "all") return config.repos
  const found = config.repos.find(r => r.name === repoFilter)
  if (!found) {
    console.error(`Unknown repo '${repoFilter}'. Run: loci ide repo ls`)
    process.exit(1)
  }
  return [found]
}

async function runRepoSearch(
  repoName: string,
  repoPath: string,
  query: string,
  limit: number,
): Promise<SearchHit[]> {
  if (!await exists(repoPath)) return []
  let proc: ReturnType<typeof Bun.spawn>
  try {
    proc = Bun.spawn([
      "rg",
      "--line-number",
      "--no-heading",
      "--smart-case",
      query,
      ".",
    ], {
      cwd: repoPath,
      stdout: "pipe",
      stderr: "pipe",
    })
  } catch {
    console.error("`rg` is required for `loci ide search`. Please install ripgrep.")
    return []
  }

  const stdout = await new Response(proc.stdout).text()
  await proc.exited
  const lines = stdout.split("\n").filter(Boolean)
  const terms = tokenizeQuery(query)
  const hits: SearchHit[] = []
  for (const line of lines.slice(0, Math.max(1, limit))) {
    const i1 = line.indexOf(":")
    const i2 = i1 >= 0 ? line.indexOf(":", i1 + 1) : -1
    if (i1 < 0 || i2 < 0) continue
    const file = line.slice(0, i1)
    const ln = parseInt(line.slice(i1 + 1, i2), 10)
    const text = line.slice(i2 + 1).trim()
    const score = scoreHit(file, text, terms)
    hits.push({
      repo: repoName,
      file,
      line: Number.isFinite(ln) ? ln : 0,
      text,
      score,
    })
  }
  return hits
}

function tokenizeQuery(query: string): string[] {
  return query
    .toLowerCase()
    .split(/\s+/)
    .map(t => t.trim())
    .filter(Boolean)
}

function scoreHit(file: string, text: string, terms: string[]): number {
  const f = file.toLowerCase()
  const t = text.toLowerCase()
  let score = 0
  for (const term of terms) {
    if (f.includes(term)) score += 3
    if (t.includes(term)) score += 2
  }
  score += Math.max(0, 4 - Math.floor(text.length / 60))
  return score
}

function newThreadId(): string {
  return `t-${Date.now()}-${randomBytes(2).toString("hex")}`
}

function codexDropboxDir(repoPath: string): string {
  return join(repoPath, ".loci", "ide", "codex-dropbox")
}

async function appendCodexMessage(repoPath: string, thread: string, message: CodexMessage): Promise<void> {
  const dir = codexDropboxDir(repoPath)
  await mkdir(dir, { recursive: true })
  const path = join(dir, `${thread}.jsonl`)
  await appendFile(path, JSON.stringify(message) + "\n")
}

async function appendLocalOutbox(thread: string, message: CodexMessage): Promise<void> {
  const dir = join(process.cwd(), ".loci", "ide", "codex-outbox")
  await mkdir(dir, { recursive: true })
  const path = join(dir, `${thread}.jsonl`)
  await appendFile(path, JSON.stringify(message) + "\n")
}

async function resolveInboxRepoPath(repoName: string | null): Promise<string> {
  if (!repoName) return process.cwd()
  const config = await loadIdeConfig()
  const found = config.repos.find(r => r.name === repoName)
  if (!found) {
    console.error(`Unknown repo '${repoName}'. Run: loci ide repo ls`)
    process.exit(1)
  }
  return found.path
}

async function readCodexMessages(repoPath: string, threadFilter: string | null): Promise<CodexMessage[]> {
  const dir = codexDropboxDir(repoPath)
  if (!await exists(dir)) return []
  const names = (await readdir(dir)).filter(n => n.endsWith(".jsonl")).sort()
  const files = threadFilter ? names.filter(n => n === `${threadFilter}.jsonl`) : names
  const messages: CodexMessage[] = []
  for (const name of files) {
    const raw = await Bun.file(join(dir, name)).text()
    for (const line of raw.split("\n")) {
      const trimmed = line.trim()
      if (!trimmed) continue
      try {
        messages.push(JSON.parse(trimmed) as CodexMessage)
      } catch {
        // ignore malformed lines
      }
    }
  }
  return messages.sort((a, b) => a.timestamp.localeCompare(b.timestamp))
}

async function loadIdeConfig(): Promise<IdeConfig> {
  if (!await exists(IDE_REPOS_FILE)) return { repos: [] }
  try {
    const parsed = JSON.parse(await Bun.file(IDE_REPOS_FILE).text()) as IdeConfig
    return { repos: Array.isArray(parsed.repos) ? parsed.repos : [] }
  } catch {
    return { repos: [] }
  }
}

async function saveIdeConfig(config: IdeConfig): Promise<void> {
  await mkdir(IDE_ROOT, { recursive: true })
  await Bun.write(IDE_REPOS_FILE, JSON.stringify(config, null, 2))
}

function nucleantPath(id: string): string {
  return join(IDE_NUCLEANTS_DIR, `${id}.json`)
}

function fingerPlanPath(id: string): string {
  return join(IDE_FINGER_DIR, `${id}.finger.plan`)
}

async function loadNucleant(id: string): Promise<NucleantRecord | null> {
  const path = nucleantPath(id)
  if (!await exists(path)) return null
  try {
    return JSON.parse(await Bun.file(path).text()) as NucleantRecord
  } catch {
    return null
  }
}

async function saveNucleant(record: NucleantRecord): Promise<void> {
  const withUpdate: NucleantRecord = {
    ...record,
    updated_at: new Date().toISOString(),
  }
  await mkdir(IDE_NUCLEANTS_DIR, { recursive: true })
  await Bun.write(nucleantPath(record.id), JSON.stringify(withUpdate, null, 2))
}

async function saveFingerPlan(record: NucleantRecord): Promise<void> {
  await mkdir(IDE_FINGER_DIR, { recursive: true })
  await Bun.write(fingerPlanPath(record.id), buildFingerPlan(record))
}

async function apiRepoList(): Promise<RepoEntry[]> {
  const config = await loadIdeConfig()
  return config.repos
}

async function apiRepoAdd(name: string, pathArg: string): Promise<{ name: string, path: string }> {
  const absPath = resolve(pathArg)
  const config = await loadIdeConfig()
  const filtered = config.repos.filter(r => r.name !== name && r.path !== absPath)
  filtered.push({ name, path: absPath })
  await saveIdeConfig({ repos: filtered.sort((a, b) => a.name.localeCompare(b.name)) })
  return { name, path: absPath }
}

async function apiSearch(query: string, repoFilter: string, limit: number): Promise<SearchHit[]> {
  const targets = await resolveSearchTargets(repoFilter)
  const hits: SearchHit[] = []
  for (const repo of targets) {
    hits.push(...await runRepoSearch(repo.name, repo.path, query, limit * 2))
  }
  hits.sort((a, b) => b.score - a.score)
  return hits.slice(0, Math.max(1, limit))
}

async function apiAsk(
  repoName: string,
  message: string,
  thread: string | null,
  from: string | null,
): Promise<{ sent: boolean, thread: string, to: string }> {
  const config = await loadIdeConfig()
  const target = config.repos.find(r => r.name === repoName)
  if (!target) throw new Error(`unknown repo '${repoName}'`)
  const nextThread = thread ?? newThreadId()
  const fromRepo = from ?? basename(process.cwd())
  const entry: CodexMessage = {
    id: randomBytes(6).toString("hex"),
    timestamp: new Date().toISOString(),
    from_repo: fromRepo,
    to_repo: repoName,
    thread: nextThread,
    message,
  }
  await appendCodexMessage(target.path, nextThread, entry)
  await appendLocalOutbox(nextThread, entry)
  return { sent: true, thread: nextThread, to: repoName }
}

async function apiInbox(
  repoName: string | null,
  thread: string | null,
  limit: number,
): Promise<CodexMessage[]> {
  const repoPath = await resolveInboxRepoPath(repoName)
  const messages = await readCodexMessages(repoPath, thread)
  return messages.slice(-Math.max(1, limit))
}

async function apiNucleantNew(
  id: string,
  title: string,
  specApi: string,
  description: string,
): Promise<NucleantRecord> {
  const now = new Date().toISOString()
  const record: NucleantRecord = {
    id,
    title,
    spec_api: specApi,
    description,
    created_at: now,
    updated_at: now,
    presented_to: [],
  }
  await saveNucleant(record)
  await saveFingerPlan(record)
  return record
}

async function apiNucleantPresent(
  id: string,
  repoNames: string[] | null,
  note: string,
): Promise<NucleantRecord> {
  const existing = await loadNucleant(id)
  if (!existing) throw new Error(`nucleant '${id}' not found`)
  const config = await loadIdeConfig()
  const targets = !repoNames || repoNames.length === 0
    ? config.repos
    : config.repos.filter(r => repoNames.includes(r.name))
  if (targets.length === 0) throw new Error("no target repos resolved")

  const thread = `nucleant-${id}`
  const fromRepo = basename(process.cwd())
  const now = new Date().toISOString()
  let record = existing
  for (const target of targets) {
    const message = [
      `[NUCLEANT:${id}] ${record.title}`,
      `spec_api=${record.spec_api}`,
      `finger_plan_ref=${fingerPlanPath(id)}`,
      `description=${record.description || "(none)"}`,
      note ? `note=${note}` : "",
    ].filter(Boolean).join("\n")
    const entry: CodexMessage = {
      id: randomBytes(6).toString("hex"),
      timestamp: now,
      from_repo: fromRepo,
      to_repo: target.name,
      thread,
      message,
    }
    await appendCodexMessage(target.path, thread, entry)
    await appendLocalOutbox(thread, entry)
    record = upsertNucleantState(record, {
      repo: target.name,
      thread,
      status: "presented",
      last_update: now,
      note: note || null,
    })
  }
  await saveNucleant(record)
  await saveFingerPlan(record)
  return record
}

async function apiNucleantMark(
  id: string,
  repo: string,
  statusRaw: string,
  note: string | null,
): Promise<NucleantRecord> {
  const status = parseNucleantStatus(statusRaw)
  if (!status) throw new Error("invalid nucleant status")
  const existing = await loadNucleant(id)
  if (!existing) throw new Error(`nucleant '${id}' not found`)
  const record = upsertNucleantState(existing, {
    repo,
    thread: `nucleant-${id}`,
    status,
    last_update: new Date().toISOString(),
    note,
  })
  await saveNucleant(record)
  await saveFingerPlan(record)
  return record
}

async function apiNucleantStatus(id: string | null | undefined): Promise<unknown> {
  if (!id) {
    return listNucleantIds()
  }
  const record = await loadNucleant(id)
  if (!record) throw new Error(`nucleant '${id}' not found`)
  const total = record.presented_to.length
  const resolved = record.presented_to.filter(s => s.status === "resolved").length
  const in_progress = record.presented_to.filter(s => s.status === "in_progress").length
  const presented = record.presented_to.filter(s => s.status === "presented").length
  return {
    ...record,
    compliance: { total, resolved, in_progress, presented },
  }
}

async function apiFingerPlan(
  id: string,
  outPath: string | null,
): Promise<{ id: string, path: string, content: string }> {
  const record = await loadNucleant(id)
  if (!record) throw new Error(`nucleant '${id}' not found`)
  const content = buildFingerPlan(record)
  const path = outPath ? resolve(outPath) : fingerPlanPath(id)
  await mkdir(outPath ? dirname(path) : IDE_FINGER_DIR, { recursive: true })
  await Bun.write(path, content)
  return { id, path, content }
}

async function listNucleantIds(): Promise<string[]> {
  if (!await exists(IDE_NUCLEANTS_DIR)) return []
  const files = (await readdir(IDE_NUCLEANTS_DIR)).filter(f => f.endsWith(".json")).sort()
  return files.map(f => f.replace(/\.json$/, ""))
}

function upsertNucleantState(record: NucleantRecord, state: NucleantRepoState): NucleantRecord {
  const kept = record.presented_to.filter(s => s.repo !== state.repo)
  return {
    ...record,
    presented_to: [...kept, state].sort((a, b) => a.repo.localeCompare(b.repo)),
  }
}

function buildFingerPlan(record: NucleantRecord): string {
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

function parseNucleantStatus(value: string): NucleantStatus | null {
  if (value === "presented") return "presented"
  if (value === "in_progress") return "in_progress"
  if (value === "resolved") return "resolved"
  return null
}

function flag(args: string[], name: string): string | null {
  const i = args.indexOf(name)
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null
}

function positionalJoin(args: string[]): string {
  const parts: string[] = []
  for (let i = 0; i < args.length; i += 1) {
    const v = args[i]
    if (v.startsWith("--")) {
      i += 1
      continue
    }
    parts.push(v)
  }
  return parts.join(" ").trim()
}

function ideUsage(): void {
  console.log(`
loci ide — cross-repo semantic search + codex-codex dropbox

USAGE
  loci ide repo add <name> <path>                 Register peer repository
  loci ide repo ls                                List registered repositories
  loci ide search <query> [--repo <name|all>]     Search registered repositories
  loci ide ask <repo> <message> [--thread <id>]   Send codex message to peer dropbox
  loci ide inbox [--repo <name>] [--thread <id>]  Read codex dropbox messages
  loci ide nucleant new <id> --spec-api <ref>     Create a multi-repo feature nucleant
  loci ide nucleant present <id> [--repos ...]    Fan out nucleant to repo dropboxes
  loci ide nucleant mark <id> --repo <n> --status Track per-repo convergence state
  loci ide nucleant status [id]                   Show nucleant registry or details
  loci ide finger plan <nucleant-id>              Emit first-class finger.plan artifact
  loci ide serve                                  Stdio JSON-RPC socket (loci/mcp/lsp)

OPTIONS
  --limit <n>      Limit returned results/messages (default: 20)
`.trim())
}
