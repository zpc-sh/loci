///|
fn build_deep_tree(depth : Int) -> MerkinTree {
  let tree = MerkinTree::new()
  let root = @hash.Hash::of_bytes(b"\x00\x00\x00\x01")
  tree.upsert_node(MerkinNode::leaf(root))

  let mut parent_id = root
  for i = 0; i < depth; i = i + 1 {
    let child_seed = to_bytes(i.to_string())
    let child_id = @hash.Hash::of_bytes(child_seed)
    let env_id = @hash.Hash::of_bytes(b"env")
    let child_node = MerkinNode::leaf(child_id).attach_envelope(env_id, [
      "token" + i.to_string(),
    ])
    tree.upsert_node(child_node)
    ignore(tree.add_child_edge(parent_id, child_id))
    parent_id = child_id
  }
  tree
}

///|
fn to_bytes(s : String) -> Bytes {
  let mut total = 0
  for _ch in s {
    total = total + 4
  }
  let buf = FixedArray::make(total, b"\x00"[0])
  let mut pos = 0
  for ch in s {
    let code = ch.to_uint()
    buf[pos] = ((code >> 24) & 0xFFU).to_byte()
    buf[pos + 1] = ((code >> 16) & 0xFFU).to_byte()
    buf[pos + 2] = ((code >> 8) & 0xFFU).to_byte()
    buf[pos + 3] = (code & 0xFFU).to_byte()
    pos = pos + 4
  }
  Bytes::from_array(buf)
}

///|
test "perf: sparse tree deep" {
  let tree = build_deep_tree(2000) // 2000 depth
  let _ = tree.sparse(["token1999"]) // should propagate from bottom to top
}
