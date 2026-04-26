// Mirrors the MoonBit model layer (model/residue.mbt, model/locus.mbt, locus/locus.mbt).
// All types are plain data — no methods — so they serialize trivially.

// --- Locus / Session / Residue (existing) ---

export type Tier = "haiku" | "sonnet" | "opus" | string

export interface Locus {
  name: string
  spirit: string
  tags: string[]
}

export interface Session {
  tier: Tier
  shortId: string
  locus: string
}

export interface Residue {
  locus: string
  tier: Tier
  sessionShortId: string
  timestamp: string          // ISO8601
  pickedUpFrom: string | null // filename of prior residue, or null for cold entry
  whatIDid: string[]
  whatILeftOpen: string[]
  recommendation: string | null
}

export interface LociConfig {
  lociRoot: string   // default: "loci"
  storePath: string  // default: ".loci/store"
}

// Subdirectories created under each locus root. Mirrors model/locus.mbt locus_subdirs().
export const LOCUS_SUBDIRS = ["affordances", "membranes", "schemas", "yata", "residue"] as const

// --- VCS Types ---

/** A content-addressed commit (analogous to git commit object). */
export interface Commit {
  hash: string             // sha256 of normalized commit content
  parentHashes: string[]   // parent commit hash(es), empty for root
  treeHash: string         // hash of the root tree manifest
  author: string           // "name <email>" or overlay id
  timestamp: string        // ISO8601
  message: string
  /** Optional envelope/seal metadata for Loci-native provenance. */
  envelopeRef?: string
  /** Boundary material hash if boundary walk was performed at commit. */
  boundaryHash?: string
}

/** A tree manifest entry — one file/dir in a commit tree. */
export interface TreeEntry {
  path: string             // relative path from repo root
  hash: string             // content hash of the blob
  size: number             // file size in bytes
  mode: "file" | "dir" | "exec" | "symlink"
}

/** The full tree manifest for a commit. */
export interface TreeManifest {
  hash: string             // hash of the serialized manifest
  entries: TreeEntry[]
}

/** A branch ref. */
export interface Branch {
  name: string
  commitHash: string       // points to tip commit
  upstream?: string        // remote tracking branch (e.g., "origin/main")
}

/** A tag ref. */
export interface Tag {
  name: string
  commitHash: string
  annotated: boolean
  message?: string
  tagger?: string
  timestamp?: string
}

/** Staging area entry (index). */
export interface StagingEntry {
  path: string
  blobHash: string
  size: number
  action: "add" | "modify" | "delete"
}

/** A diff hunk between two file versions. */
export interface DiffHunk {
  oldStart: number
  oldCount: number
  newStart: number
  newCount: number
  lines: DiffLine[]
}

export interface DiffLine {
  type: "add" | "remove" | "context"
  content: string
  oldLine?: number
  newLine?: number
}

/** Diff for a single file. */
export interface FileDiff {
  path: string
  status: "added" | "modified" | "deleted" | "renamed"
  oldPath?: string         // for renames
  hunks: DiffHunk[]
  binary: boolean
}

/** Remote registry configuration. */
export interface RemoteConfig {
  name: string
  url: string              // OCI registry URL or loci:// address
  pushUrl?: string
}

/** Stash entry. */
export interface StashEntry {
  index: number
  message: string
  timestamp: string
  treeHash: string
  parentHash: string
}

/** Repository HEAD state. */
export interface HeadState {
  type: "branch" | "detached"
  ref: string              // branch name or commit hash
}

// --- FSM / Arblock Types ---

/** Arblock lifecycle states (from ARBLOCK_PLAN_PROFILE.md). */
export type ArblockState = "open" | "forming" | "building" | "aperturing" | "sealed" | "superseded"

/** An arblock — bounded sealed work unit. */
export interface Arblock {
  name: string
  state: ArblockState
  materialHash?: string
  parentRefs: string[]     // parent arblock names (for supersession)
  sourceLocus: string
  createdAt: string
  sealedAt?: string
  entries: ArblockEntry[]
  sealRefs: string[]
}

/** One entry in an arblock. */
export interface ArblockEntry {
  family: "form" | "fruition" | "aperture" | "seal" | "handoff" | "surface"
  name: string
  state: "open" | "converging" | "resolved" | "sealed" | "blocked" | "reopened"
  artifactRef?: string
  holeId?: string
}

/** Locus crossing passport (from LOCUS_MEMBRANE_PROFILE.md). */
export interface CrossingPassport {
  kind: string             // "loci.crossing.passport"
  version: string          // "v0"
  passportId: string
  who: {
    overlay: string
    family: string
    sessionSurface: string
  }
  what: {
    artifactRef: string
    artifactType: string
  }
  why: {
    intent: string
    note: string
  }
  where: {
    sourceLocus: string
    targetLocus: string
  }
  howFar: {
    boundaryMode: "observe" | "sanitize" | "strict" | "quarantine"
    allowedSurfaces: string[]
    budgetClass: "tiny" | "normal" | "large"
  }
  trace: {
    contextRef: string
    lineageRef: string
  }
  seal?: {
    requestSeal?: string
    materialHash?: string
    provenanceSeal?: string
  }
}

/** Membrane crossing report (recorded). */
export interface CrossingRecord {
  passportId: string
  sourceLocus: string
  targetLocus: string
  admitted: boolean
  rejection?: string
  timestamp: string
  boundaryMode: string
}

/** Boundary walk finding. */
export interface BoundaryFinding {
  fieldKey: string
  rawValue: string
  canonicalValue: string
  ghostU200b: number
  ghostU200c: number
  ghostUfeff: number
  bidiControls: number
  asciiControls: number
  suspicious: boolean
}

/** Boundary walk status. */
export type BoundaryStatus = "clean" | "attention" | "containment"
