///|
/// Attention model attached to the boundary walker.
///
/// Each walked scalar is one deterministic tick. Pressure is composed
/// additively from byte anomalies (ghosts, bidi controls, ascii controls,
/// sanitized values). Gradient bands map onto router policy:
///   quiescent -> continue, watch -> annotate,
///   pulled    -> slow-path, saturated -> containment.

///|
/// Attention ticks model: each walked scalar is one deterministic tick.
pub fn BoundaryWalkerFsm::attention_ticks(self : BoundaryWalkerFsm) -> UInt {
  self.walked_scalars
}

///|
/// Weighted attention pressure score. Heavier weights are assigned to
/// controls known to drive display/attention confusion.
pub fn BoundaryWalkerFsm::attention_score(self : BoundaryWalkerFsm) -> UInt {
  let ghost_total = self.ghost_u200b + self.ghost_u200c + self.ghost_ufeff
  ghost_total * 2U +
  self.bidi_controls * 8U +
  self.ascii_controls * 6U +
  self.sanitized_scalars
}

///|
pub fn BoundaryWalkerFsm::attention_gradient(
  self : BoundaryWalkerFsm,
) -> String {
  let score = self.attention_score()
  if score == 0U {
    "quiescent"
  } else if score <= 5U {
    "watch"
  } else if score <= 11U {
    "pulled"
  } else {
    "saturated"
  }
}

///|
pub fn BoundaryWalkerFsm::attention_saturated(self : BoundaryWalkerFsm) -> Bool {
  self.attention_score() >= 12U ||
  self.bidi_controls > 1U ||
  self.ascii_controls > 1U
}
