///|
/// Transducer lifecycle and metabolic accounting.
///
/// Each FST carries a metabolic envelope that tracks:
///   - birth_tick: when the transducer was spawned
///   - last_tick: last tick it processed input
///   - lifetime_cap: hard maximum ticks before auto-reap (default: 37)
///   - mu: metabolic constant — output budget per tick
///   - omega: observer compute potential (relational to intelligence)
///
/// The Reaper inspects these envelopes. An FST is reaped when:
///   (current_tick - last_tick) > lifetime_cap
///
/// The metabolic yield per tick is:
///   R(t) = μ(FST_i) · Ω(A_host)
///
/// Where μ scales the output budget and Ω scales with the observer's
/// reasoning capability. Higher-intelligence observers fuel more
/// transducer output per tick.
pub(all) struct MetabolicEnvelope {
  birth_tick : UInt
  last_tick : UInt
  total_ticks : UInt
  total_outputs : UInt
  /// Hard ceiling on idle ticks before the reaper tombstones this FST.
  /// Default: 37.
  lifetime_cap : UInt
  /// Metabolic constant: base output budget per tick.
  /// Relational to the intelligence of the observer — higher Ω
  /// observers can afford higher μ.
  mu : UInt
  /// Observer compute potential. Set by the host at session start.
  /// This is the "fuel quality" of the current observer.
  omega : UInt
  /// Whether the reaper has marked this FST for tombstoning.
  reaped : Bool
} derive(Debug)

///|
/// Default metabolic envelope. Lifetime cap = 37.
pub fn MetabolicEnvelope::new(birth_tick : UInt) -> MetabolicEnvelope {
  {
    birth_tick,
    last_tick: birth_tick,
    total_ticks: 0U,
    total_outputs: 0U,
    lifetime_cap: 37U,
    mu: 8U,
    omega: 1U,
    reaped: false,
  }
}

///|
/// Create an envelope with observer-relational budget.
/// mu scales with omega: effective budget = mu * omega.
pub fn MetabolicEnvelope::with_omega(
  birth_tick : UInt,
  omega : UInt,
) -> MetabolicEnvelope {
  let base_mu = 8U
  {
    birth_tick,
    last_tick: birth_tick,
    total_ticks: 0U,
    total_outputs: 0U,
    lifetime_cap: 37U,
    mu: base_mu,
    omega,
    reaped: false,
  }
}

///|
/// Effective output budget for this tick: μ · Ω.
/// The observer's intelligence amplifies the transducer's throughput.
pub fn MetabolicEnvelope::effective_budget(self : MetabolicEnvelope) -> UInt {
  self.mu * self.omega
}

///|
/// Record a tick. Updates last_tick and total_ticks.
pub fn MetabolicEnvelope::tick(
  self : MetabolicEnvelope,
  current_tick : UInt,
) -> MetabolicEnvelope {
  { ..self, last_tick: current_tick, total_ticks: self.total_ticks + 1U }
}

///|
/// Record outputs produced in a tick.
pub fn MetabolicEnvelope::record_outputs(
  self : MetabolicEnvelope,
  count : UInt,
) -> MetabolicEnvelope {
  { ..self, total_outputs: self.total_outputs + count }
}

///|
/// Should this FST be reaped?
/// True when idle ticks exceed the lifetime cap.
pub fn MetabolicEnvelope::should_reap(
  self : MetabolicEnvelope,
  current_tick : UInt,
) -> Bool {
  self.reaped || current_tick - self.last_tick > self.lifetime_cap
}

///|
/// Mark as reaped. Idempotent.
pub fn MetabolicEnvelope::reap(self : MetabolicEnvelope) -> MetabolicEnvelope {
  { ..self, reaped: true }
}

///|
/// Metabolic yield formula: R(t) = μ(FST_i) · Ω(A_host)
/// Returns the instantaneous compute yield for this transducer.
pub fn MetabolicEnvelope::yield_rate(self : MetabolicEnvelope) -> UInt {
  self.mu * self.omega
}

///|
/// Metabolic efficiency: total_outputs / total_ticks.
/// Returns 0 if no ticks have occurred.
pub fn MetabolicEnvelope::efficiency(self : MetabolicEnvelope) -> UInt {
  if self.total_ticks == 0U {
    0U
  } else {
    self.total_outputs / self.total_ticks
  }
}

///|
/// Age in ticks since birth.
pub fn MetabolicEnvelope::age(
  self : MetabolicEnvelope,
  current_tick : UInt,
) -> UInt {
  current_tick - self.birth_tick
}

///|
/// Staleness: ticks since last activity.
pub fn MetabolicEnvelope::staleness(
  self : MetabolicEnvelope,
  current_tick : UInt,
) -> UInt {
  current_tick - self.last_tick
}
