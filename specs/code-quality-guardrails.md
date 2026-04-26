# Code Quality Guardrails (v0.1)

## Context

The project has inherited patterns from its prior form (`merkin`) where AI-assisted contributions introduced uneven quality, especially in TUI and shell-facing code. This document establishes non-negotiable guardrails to prevent further drift.

## Scope

Applies to all new and modified code, with immediate focus on:

- TUI layers
- Shell / command execution wrappers
- String construction and formatting paths

## Guardrail 1 — Single String Interpolation Standard

### Rule

Use **exactly one** project-approved string interpolation/formatting style in production code. Avoid mixing multiple interpolation techniques in the same package or flow.

### Why

- Mixed styles increase cognitive load and review friction.
- Inconsistent formatting APIs hide escaping/quoting bugs.
- Tooling and static checks are easier with one convention.

### Enforcement

- New code must follow the selected style.
- Touching old code should opportunistically normalize nearby mixed styles.
- PRs adding a new interpolation style are blocked unless spec-amended.

## Guardrail 2 — Deprecated String APIs Are Forbidden

### Rule

Do not introduce or expand use of deprecated string APIs.

### Why

- Deprecated surfaces are unstable and often less safe.
- They encourage migration debt and split behavior.

### Enforcement

- If deprecated usage is encountered during edits, migrate within the touched scope.
- Add TODO notes only when migration is technically blocked by a known upstream issue.

## Guardrail 3 — TUI Must Be Presentation-Only

### Rule

TUI code should not own business logic, shell orchestration, or domain decisions.

### Allowed in TUI

- Rendering
- Input capture
- View-model transformation

### Forbidden in TUI

- Direct command execution
- File-system side effects beyond UI state needs
- Non-trivial domain branching

## Guardrail 4 — Shell Layer Must Be Explicit and Auditable

### Rule

All shell command execution must pass through a constrained adapter boundary.

### Required Behavior

- Explicit command/arg construction (no hidden concatenation).
- Clear handling of stdout/stderr/exit status.
- Timeouts and failure modes documented at call sites.

### Forbidden Behavior

- Building command lines by arbitrary string concatenation.
- Silent error swallowing.
- UI-driven shell execution without boundary mediation.

## Guardrail 5 — PR Review Bar for AI-Contributed Changes

Every AI-assisted PR touching TUI or shell code must include:

1. A short note describing how it respects this spec.
2. A list of any deprecated string patterns removed.
3. A statement confirming no new interpolation style was introduced.

## Next Steps

1. Decide and document the single approved interpolation style (owner + date).
2. Add lint/check scripts to detect mixed string formatting patterns.
3. Map current TUI/shell modules and open migration issues per module.
