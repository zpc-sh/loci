///|
test "map_yata_action supports contract-bind" {
  @test.assert_eq(map_yata_action("contract-bind"), "yata-contract-bind")
}

///|
test "bridge-only includes yata contract bind" {
  assert_true(action_is_bridge_only("yata-contract-bind"))
}

///|
test "build contract-bind bridge command defaults and overrides" {
  let default_cmd = build_yata_contract_bind_bridge_command([])
  @test.assert_eq(
    default_cmd, "docs/archive/tools/chatgpt-contract-binding-generate.sh loci/chatgpt",
  )

  let custom_cmd = build_yata_contract_bind_bridge_command([
    "--out-root", "loci/chatgpt-alt", "--generated-at-utc", "2026-04-26T07:00:00Z",
  ])
  @test.assert_eq(
    custom_cmd, "docs/archive/tools/chatgpt-contract-binding-generate.sh loci/chatgpt-alt 2026-04-26T07:00:00Z",
  )
}

///|
test "map conv action supports append-dialogue" {
  @test.assert_eq(map_conv_action("append-dialogue"), "conv-append-dialogue")
}

///|
test "bridge-only includes conv append dialogue" {
  assert_true(action_is_bridge_only("conv-append-dialogue"))
}

///|
test "build conv append dialogue command defaults and content-file mode" {
  let default_cmd = build_conv_append_dialogue_bridge_command([])
  @test.assert_eq(
    default_cmd, "docs/archive/tools/chatgpt-codex-dialogue-append.sh --out-root loci/chatgpt --speaker codex --kind contract_spec_proof_design --topic meta-codex --content meta-codex-iteration",
  )

  let file_cmd = build_conv_append_dialogue_bridge_command([
    "--out-root", "loci/chatgpt", "--speaker", "chatgpt", "--dialogue-kind", "meta_dialogue",
    "--topic", "contract-review", "--refs", "loci/chatgpt/specs/chatgpt-contract-binding.muon",
    "--content-file", "/tmp/msg.txt", "--generated-at-utc", "2026-04-26T08:00:00Z",
  ])
  @test.assert_eq(
    file_cmd, "docs/archive/tools/chatgpt-codex-dialogue-append.sh --out-root loci/chatgpt --speaker chatgpt --kind meta_dialogue --topic contract-review --refs loci/chatgpt/specs/chatgpt-contract-binding.muon --content-file /tmp/msg.txt --ts 2026-04-26T08:00:00Z",
  )
}
