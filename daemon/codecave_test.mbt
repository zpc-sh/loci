///|
/// Build an edition whose `content_hash` matches the payload.
fn good_edition_fixture(edition_id : String) -> @model.NewsEdition {
  let sections = [
    @model.NewsSection::{
      slug: "summary",
      body: "cross-tier orientation stable; no adversarial surges observed",
    },
    @model.NewsSection::{ slug: "trust_desk", body: "CNI verified" },
  ]
  let continuity : @model.NewsContinuity = {
    new_count: 2U,
    continuing_count: 4U,
    resolved_count: 1U,
    quiet_count: 0U,
  }
  let confidence : @model.NewsConfidence = {
    observed_count: 3U,
    inferred_count: 2U,
    unconfirmed_count: 1U,
  }
  // Seed with a placeholder and then replace content_hash with the
  // canonical one computed from the payload.
  let placeholder = @hash.Hash::of_bytes(b"\x00")
  let seed = @model.NewsEdition::new(
    edition_id,
    "2026-04-20T12:00:00Z",
    "cni-agent-1",
    @model.NetworkCni,
    placeholder,
    Some(@hash.Hash::of_bytes(b"\xf0")),
    sections,
    continuity,
    confidence,
  )
  let canonical_hash = seed.compute_content_hash()
  @model.NewsEdition::{ ..seed, content_hash: canonical_hash }
}

///|
test "Codecave verifies a clean news edition" {
  let edition = good_edition_fixture("ed-ok-001")
  let cave = @daemon.Codecave::new(true)
    .offer(@daemon.NewsEnvelope(edition))
    .drain_inbox()
  @test.assert_eq(cave.verified.length(), 1)
  @test.assert_eq(cave.quarantine.length(), 0)
  let boot = cave.boot_hook()
  match boot.news_edition_hash {
    Some(_) => assert_true(true)
    None => assert_true(false)
  }
  assert_true(boot.news_context_block.contains("[loci-news]"))
  assert_true(boot.news_context_block.contains("ed-ok-001"))
}

///|
test "Codecave quarantines tampered content" {
  let base = good_edition_fixture("ed-tamper-001")
  let tampered = @model.NewsEdition::{
    ..base,
    sections: [
      @model.NewsSection::{ slug: "summary", body: "mutated-after-seal" },
    ],
  }
  let cave = @daemon.Codecave::new(true)
    .offer(@daemon.NewsEnvelope(tampered))
    .drain_inbox()
  @test.assert_eq(cave.verified.length(), 0)
  @test.assert_eq(cave.quarantine.length(), 1)
  assert_true(
    cave.quarantine[0].reason.contains("content:CONTENT_HASH_MISMATCH"),
  )
}

///|
test "Codecave requires signature in guarded mode" {
  let base = good_edition_fixture("ed-unsigned-001")
  let unsigned = @model.NewsEdition::{ ..base, signature: None }
  let cave = @daemon.Codecave::new(true)
    .offer(@daemon.NewsEnvelope(unsigned))
    .drain_inbox()
  @test.assert_eq(cave.verified.length(), 0)
  @test.assert_eq(cave.quarantine.length(), 1)
  assert_true(cave.quarantine[0].reason.contains("MISSING_SIGNATURE"))
}

///|
test "Codecave admits unsigned edition in bootstrap mode" {
  let base = good_edition_fixture("ed-boot-001")
  let unsigned = @model.NewsEdition::{ ..base, signature: None }
  // Bootstrap mode (guarded=false) permits unsigned editions.
  let cave = @daemon.Codecave::new(false)
    .offer(@daemon.NewsEnvelope(unsigned))
    .drain_inbox()
  @test.assert_eq(cave.verified.length(), 1)
  @test.assert_eq(cave.quarantine.length(), 0)
}

///|
test "Codecave quarantines oversized section" {
  let big = StringBuilder::new(size_hint=8192)
  let mut i = 0
  while i < 8192 {
    big.write_char('x')
    i = i + 1
  }
  let sections = [
    @model.NewsSection::{ slug: "summary", body: big.to_string() },
  ]
  let seed = @model.NewsEdition::new(
    "ed-big-001",
    "2026-04-20T00:00:00Z",
    "cni-agent-1",
    @model.NetworkCni,
    @hash.Hash::of_bytes(b"\x01"),
    Some(@hash.Hash::of_bytes(b"\xf0")),
    sections,
    { new_count: 1U, continuing_count: 0U, resolved_count: 0U, quiet_count: 0U },
    { observed_count: 1U, inferred_count: 0U, unconfirmed_count: 0U },
  )
  let edition = @model.NewsEdition::{
    ..seed,
    content_hash: seed.compute_content_hash(),
  }
  let cave = @daemon.Codecave::new(true)
    .offer(@daemon.NewsEnvelope(edition))
    .drain_inbox()
  @test.assert_eq(cave.verified.length(), 0)
  @test.assert_eq(cave.quarantine.length(), 1)
  assert_true(cave.quarantine[0].reason.contains("SECTION_OVERSIZE"))
}

///|
test "Codecave ingests a resonance AMF broadcast as ambient" {
  let amf = @model.AmfDocument::grounded("res-bcast-001")
  let cave = @daemon.Codecave::new(true)
    .offer(@daemon.ResonanceEnvelope(amf))
    .drain_inbox()
  @test.assert_eq(cave.verified.length(), 1)
  let boot = cave.boot_hook()
  match boot.resonance_signature {
    Some(sig) => @test.assert_eq(sig, amf.signature())
    None => assert_true(false)
  }
  assert_true(boot.resonance_summary.contains("[loci-resonance]"))
  assert_true(boot.resonance_summary.contains("res-bcast-001"))
}

///|
test "Codecave quarantines out-of-range AMF" {
  let base = @model.AmfDocument::grounded("res-bad-001")
  let bad = @model.AmfDocument::{
    ..base,
    consciousness: @model.AmfConsciousness::{
      ..base.consciousness,
      cognitive_load: 2.5,
    },
  }
  let cave = @daemon.Codecave::new(true)
    .offer(@daemon.ResonanceEnvelope(bad))
    .drain_inbox()
  @test.assert_eq(cave.verified.length(), 0)
  @test.assert_eq(cave.quarantine.length(), 1)
  assert_true(cave.quarantine[0].reason.contains("OUT_OF_RANGE"))
}

///|
test "Codecave routes both lanes independently" {
  let edition = good_edition_fixture("ed-mix-001")
  let amf = @model.AmfDocument::grounded("res-mix-001")
  let cave = @daemon.Codecave::new(true)
    .offer(@daemon.NewsEnvelope(edition))
    .offer(@daemon.ResonanceEnvelope(amf))
    .drain_inbox()
  @test.assert_eq(cave.verified.length(), 2)
  let boot = cave.boot_hook()
  match boot.news_edition_hash {
    Some(_) => assert_true(true)
    None => assert_true(false)
  }
  match boot.resonance_signature {
    Some(_) => assert_true(true)
    None => assert_true(false)
  }
}

///|
test "Codecave quarantines unknown envelope kind" {
  let cave = @daemon.Codecave::new(true)
    .offer(
      @daemon.RawEnvelope("something.random", @hash.Hash::of_bytes(b"\x99")),
    )
    .drain_inbox()
  @test.assert_eq(cave.verified.length(), 0)
  @test.assert_eq(cave.quarantine.length(), 1)
  assert_true(cave.quarantine[0].reason.contains("unknown_kind"))
}
