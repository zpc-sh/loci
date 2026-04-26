///|
test "create_hall returns hall with sequential id" {
  let host = @daemon.ConversationHost::new()
  let hall = host.create_hall("saba-main", "debate-default")
  assert_eq(hall.hall_id, "hall-1")
  assert_eq(hall.name, "saba-main")
  assert_eq(hall.policy_profile, "debate-default")
  assert_eq(hall.created_at_seq, 1U)
}

///|
test "create_thread returns Some anchored to hall with head checkpoint set" {
  let host = @daemon.ConversationHost::new()
  let hall = host.create_hall("saba-main", "debate-default")
  match host.create_thread(hall.hall_id, "fsm-debate", @daemon.Program) {
    Some(thread) => {
      assert_eq(thread.hall_id, hall.hall_id)
      assert_eq(thread.topic, "fsm-debate")
      assert_eq(thread.track, @daemon.Program)
      assert_true(thread.head_checkpoint != "")
    }
    None => assert_true(false)
  }
}

///|
test "create_thread returns None for unknown hall" {
  let host = @daemon.ConversationHost::new()
  assert_true(
    host.create_thread("no-such-hall", "topic", @daemon.Program) is None,
  )
}

///|
test "append_turn rejects unknown thread_id" {
  let host = @daemon.ConversationHost::new()
  let outcome = host.append_turn(
    "bad-thread",
    @daemon.TurnRequest::default("hello"),
  )
  assert_eq(outcome.accepted, false)
  assert_eq(outcome.issues[0].code, "BAD_REQUEST")
}

///|
test "append_turn rejects empty actor_overlay" {
  let host = @daemon.ConversationHost::new()
  let hall = host.create_hall("h", "p")
  match host.create_thread(hall.hall_id, "t", @daemon.Program) {
    Some(thread) => {
      let req : @daemon.TurnRequest = {
        ..@daemon.TurnRequest::default("content"),
        actor_overlay: "",
      }
      let outcome = host.append_turn(thread.thread_id, req)
      assert_eq(outcome.accepted, false)
      assert_eq(outcome.issues[0].code, "BAD_REQUEST")
    }
    None => assert_true(false)
  }
}

///|
test "append_turn rejects duplicate idempotency key" {
  let host = @daemon.ConversationHost::new()
  let hall = host.create_hall("h", "p")
  match host.create_thread(hall.hall_id, "t", @daemon.Program) {
    Some(thread) => {
      let req : @daemon.TurnRequest = {
        ..@daemon.TurnRequest::default("first"),
        idempotency_key: "key-abc",
      }
      let first = host.append_turn(thread.thread_id, req)
      assert_eq(first.accepted, true)
      let dup : @daemon.TurnRequest = {
        ..@daemon.TurnRequest::default("second"),
        idempotency_key: "key-abc",
      }
      let second = host.append_turn(thread.thread_id, dup)
      assert_eq(second.accepted, false)
      assert_eq(second.issues[0].code, "CONFLICTING_IDEMPOTENCY_KEY")
    }
    None => assert_true(false)
  }
}

///|
test "append_turn rejects content outside length envelope" {
  let host = @daemon.ConversationHost::new()
  let hall = host.create_hall("h", "p")
  match host.create_thread(hall.hall_id, "t", @daemon.Program) {
    Some(thread) => {
      let tight_envelope : @daemon.LengthEnvelope = {
        ..@daemon.LengthEnvelope::default(),
        input_len_max: 3U,
      }
      let req : @daemon.TurnRequest = {
        ..@daemon.TurnRequest::default("this is way too long"),
        length_envelope: tight_envelope,
      }
      let outcome = host.append_turn(thread.thread_id, req)
      assert_eq(outcome.accepted, false)
      assert_eq(outcome.issues[0].code, "LENGTH_ENVELOPE_VIOLATION")
    }
    None => assert_true(false)
  }
}

///|
test "replay returns correct counts for a clean three-turn window" {
  let host = @daemon.ConversationHost::new()
  let hall = host.create_hall("h", "p")
  match host.create_thread(hall.hall_id, "t", @daemon.Program) {
    Some(thread) => {
      ignore(
        host.append_turn(thread.thread_id, @daemon.TurnRequest::default("a")),
      )
      ignore(
        host.append_turn(thread.thread_id, @daemon.TurnRequest::default("b")),
      )
      ignore(
        host.append_turn(thread.thread_id, @daemon.TurnRequest::default("c")),
      )
      let result = host.replay(
        thread.thread_id,
        @daemon.ReplayRequest::default(),
      )
      assert_eq(result.ok, true)
      assert_eq(result.replayed_count, 3U)
      assert_eq(result.non_replayable_count, 0U)
    }
    None => assert_true(false)
  }
}

///|
test "replay returns not-ok for unknown thread_id" {
  let host = @daemon.ConversationHost::new()
  let result = host.replay("no-thread", @daemon.ReplayRequest::default())
  assert_eq(result.ok, false)
  assert_eq(result.replayed_count, 0U)
}

///|
test "create_checkpoint returns Some with correct label" {
  let host = @daemon.ConversationHost::new()
  let hall = host.create_hall("h", "p")
  match host.create_thread(hall.hall_id, "t", @daemon.Program) {
    Some(thread) =>
      match host.create_checkpoint(thread.thread_id, "snapshot-1") {
        Some(cp) => {
          assert_eq(cp.label, "snapshot-1")
          assert_eq(cp.thread_id, thread.thread_id)
        }
        None => assert_true(false)
      }
    None => assert_true(false)
  }
}

///|
test "record_embedding returns Some and purge removes expired ephemeral records" {
  let host = @daemon.ConversationHost::new()
  let hall = host.create_hall("h", "p")
  match host.create_thread(hall.hall_id, "t", @daemon.Program) {
    Some(thread) => {
      let record = host.record_embedding(
        thread.thread_id,
        "model/yata.mbt",
        "mbt",
        "text/plain",
        true,
        1U,
        @daemon.Observe,
        true,
        2U,
        "test embedding",
      )
      match record {
        Some(r) => {
          assert_eq(r.record_id, "embed-1")
          assert_eq(r.file_ref, "model/yata.mbt")
          assert_eq(r.ephemeral, true)
        }
        None => assert_true(false)
      }
      let purged = host.purge_embedding_records(thread.thread_id, 2U)
      assert_eq(purged, 1U)
      assert_eq(host.embedding_timeline(thread.thread_id).length(), 0)
    }
    None => assert_true(false)
  }
}

///|
test "emit_embedding_plan returns Some wire for thread with embeddings" {
  let host = @daemon.ConversationHost::new()
  let hall = host.create_hall("h", "p")
  match host.create_thread(hall.hall_id, "t", @daemon.Program) {
    Some(thread) => {
      ignore(
        host.record_embedding(
          thread.thread_id,
          "model/yata.mbt",
          "mbt",
          "text/plain",
          true,
          1U,
          @daemon.Observe,
          false,
          0U,
          "plan test",
        ),
      )
      match
        host.emit_embedding_plan(
          thread.thread_id,
          "chatgpt",
          "shared",
          "substrate://loc/chatgpt",
          "test-gen",
          "test note",
        ) {
        Some(wire) => {
          assert_true(wire.contains("kind:"))
          assert_true(wire.contains("embedding"))
        }
        None => assert_true(false)
      }
    }
    None => assert_true(false)
  }
}
