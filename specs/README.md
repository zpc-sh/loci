# Specs Workspace

This folder is the working area for project-level engineering specifications.

## Purpose

- Capture explicit guardrails before implementation.
- Reduce architecture drift and avoid repeated code smells.
- Give contributors (human + AI) one source of truth for coding expectations.

## Current specs

- `code-quality-guardrails.md` — baseline standards for string handling and TUI/shell boundaries.
- `git-replacement-testing-dimensions.md` — test matrix and evidence bar for Git-replacement claims.

## Process

1. Write/adjust specs here first.
2. Agree on the spec in PR discussion.
3. Implement changes in code that reference the spec.
4. Keep specs updated as constraints evolve.
