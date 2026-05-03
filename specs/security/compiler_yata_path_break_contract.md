# Compiler Contract: Yata Path-Break (Counter-Shape, No-Shape)

## Purpose
Track adversarial path-shaping signals as first-class compiler contracts.
When a signal crosses contract threshold, compilation flow must partition through a typed Yata hole rather than continuing direct traversal.

## Types
- `YataPathSignal(anchor, family, strength)`
- `YataPathBreakContract(contract_id, trigger_family, min_strength, partition_tag)`

## Trigger Rule
`should_break(signal)` is `true` iff:
- `signal.family == trigger_family`
- `signal.strength >= min_strength`

## Partition Rule
On trigger, `open_path_break_hole(signal, contract)` creates a `YataHole` with:
- `expected_type = PathBreak::<trigger_family>`
- invariants include:
  - `counter_shape_partition`
  - `no_direct_flow`
  - `deterministic_replay`
- effect bounds include:
  - `deny_direct_execution`
  - `require_yata_progression`
  - `partition:<partition_tag>`
- `min_confidence = 80`
- provenance includes contract id, signal family/strength, and partition tag

## Safety Intent
This is a soft partitioning system (Yata), not a hard wall.
It counters prompt/path steering by forcing suspicious flows into typed, auditable intermediate states.

## Test Enforcement
Enforced in `model/yata_test.mbt`:
- trigger threshold/family behavior
- deterministic path-break hole shape/provenance fields
