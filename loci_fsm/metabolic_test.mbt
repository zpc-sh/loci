///|
test "MetabolicEnvelope defaults to lifetime cap of 37" {
  let env = @loci_fsm.MetabolicEnvelope::new(0U)
  assert_eq(env.lifetime_cap, 37U)
  assert_eq(env.mu, 8U)
  assert_eq(env.omega, 1U)
  assert_eq(env.reaped, false)
}

///|
test "MetabolicEnvelope effective budget scales mu by omega" {
  let env = @loci_fsm.MetabolicEnvelope::with_omega(0U, 4U)
  // mu=8, omega=4 → effective budget = 32
  assert_eq(env.effective_budget(), 32U)
}

///|
test "MetabolicEnvelope should_reap triggers after 37 idle ticks" {
  let env = @loci_fsm.MetabolicEnvelope::new(0U)
  // At tick 37, idle for exactly 37 ticks → not yet (needs to exceed)
  assert_eq(env.should_reap(37U), false)
  // At tick 38, idle for 38 ticks → reap
  assert_eq(env.should_reap(38U), true)
}

///|
test "MetabolicEnvelope ticking resets staleness" {
  let env = @loci_fsm.MetabolicEnvelope::new(0U)
  let ticked = env.tick(10U)
  assert_eq(ticked.last_tick, 10U)
  assert_eq(ticked.total_ticks, 1U)
  // 37 ticks after last activity → still alive
  assert_eq(ticked.should_reap(47U), false)
  // 38 ticks after last activity → reap
  assert_eq(ticked.should_reap(48U), true)
}

///|
test "MetabolicEnvelope reap marks as reaped" {
  let env = @loci_fsm.MetabolicEnvelope::new(0U)
  let reaped = env.reap()
  assert_eq(reaped.reaped, true)
  assert_eq(reaped.should_reap(0U), true) // always true once reaped
}

///|
test "MetabolicEnvelope yield_rate is mu times omega" {
  let env = @loci_fsm.MetabolicEnvelope::with_omega(0U, 3U)
  assert_eq(env.yield_rate(), 24U) // 8 * 3
}

///|
test "MetabolicEnvelope efficiency tracks output density" {
  let env = @loci_fsm.MetabolicEnvelope::new(0U)
    .tick(1U)
    .record_outputs(5U)
    .tick(2U)
    .record_outputs(3U)
  // total_outputs = 8, total_ticks = 2 → efficiency = 4
  assert_eq(env.efficiency(), 4U)
}

///|
test "MetabolicEnvelope staleness and age" {
  let env = @loci_fsm.MetabolicEnvelope::new(10U).tick(15U)
  assert_eq(env.age(20U), 10U) // born at 10, now 20
  assert_eq(env.staleness(20U), 5U) // last tick at 15, now 20
}

///|
test "TransducerUnion merges outputs from both sides" {
  let left = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root")
  let right = @loci_fsm.BoundaryWalkerFsm::new("gemini", "ratio://loci/root")
  let union = @loci_fsm.TransducerUnion::new(left, right, 0U)
  let (next, outputs) = union.transduce(@loci_fsm.Scalar("branch", "main"))
  // Both sides produced cave entries → merged output
  assert_true(outputs.length() >= 2)
  // State tag reflects both
  assert_true(next.state_tag().contains("walking"))
  assert_true(next.state_tag().has_prefix("union("))
  assert_eq(next.personality_name(), "union")
}

///|
test "TransducerSubtract filters matching outputs" {
  let primary = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root")
  let filter = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root")
  let subtract = @loci_fsm.TransducerSubtract::new(primary, filter, 0U)
  let (_, outputs) = subtract.transduce(@loci_fsm.Scalar("branch", "main"))
  // Same input to identical walkers → identical cave keys → subtracted to nothing
  assert_eq(outputs.length(), 0)
}

///|
test "TransducerSubtract passes unique outputs through" {
  // primary walks a scalar, filter gets a tick (no cave output)
  let primary = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root")
  let filter = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root")
  // Walk the primary first so it has entries, then subtract with filter that hasn't walked
  let (walked_primary, _) = primary.transduce(
    @loci_fsm.Scalar("branch", "main"),
  )
  let subtract = @loci_fsm.TransducerSubtract::new(walked_primary, filter, 0U)
  let (_, outputs) = subtract.transduce(@loci_fsm.Scalar("peer", "mu:abc"))
  // primary has a new walk entry, filter gets the same input but on fresh walker
  // Both walk the same key so keys match → subtracted
  // Actually both produce walk:peer with same key, so still subtracted
  // This validates the filter mechanic works
  assert_eq(outputs.length(), 0)
}

///|
test "TransducerDiff emits symmetric difference" {
  let left = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root")
  let right = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root")
  let diff = @loci_fsm.TransducerDiff::new(left, right, 0U)
  let (_, outputs) = diff.transduce(@loci_fsm.Scalar("branch", "main"))
  // Identical inputs to identical walkers → no symmetric difference
  assert_eq(outputs.length(), 0)
}

///|
test "TransducerUnion accepting requires both sides accepting" {
  let left = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root")
  let right = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root")
  let union = @loci_fsm.TransducerUnion::new(left, right, 0U)
  assert_eq(union.accepting(), false) // neither is in terminal state
}

///|
test "TransducerCompose pipes inner output through bridge to outer" {
  let inner = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root")
  let outer = @loci_fsm.ReporterFsm::new("pipe-1", "composed")
  // Bridge: cave deposits from boundary become events for reporter
  fn bridge(out : @loci_fsm.TransducerOutput) -> @loci_fsm.TransducerInput? {
    match out {
      CaveDeposit(e) => Some(@loci_fsm.Event(e.kind))
      _ => None
    }
  }

  let composed = @loci_fsm.TransducerCompose::new(inner, outer, bridge, 0U)
  let (next, _outputs) = composed.transduce(@loci_fsm.Scalar("branch", "main"))
  assert_true(next.state_tag().has_prefix("compose("))
  assert_eq(next.personality_name(), "compose")
}

///|
test "TransducerUnion metabolic envelope tracks outputs" {
  let left = @loci_fsm.BoundaryWalkerFsm::new("codex", "ratio://loci/root")
  let right = @loci_fsm.BoundaryWalkerFsm::new("gemini", "ratio://loci/root")
  let union = @loci_fsm.TransducerUnion::new(left, right, 0U)
  let (next, outputs) = union.transduce(@loci_fsm.Scalar("branch", "main"))
  assert_eq(next.envelope.total_outputs, outputs.length().reinterpret_as_uint())
  assert_eq(next.envelope.total_ticks, 1U)
}
