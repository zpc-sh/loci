///|
fn bench_join_by(b: @bench.B) {
  let items = []
  for i = 0; i < 1000; i = i + 1 {
    items.push("item" + i.to_string())
  }
  b.run("join_by", fn() {
    let _ = join_by(items, ",")
  })
}

///|
fn join_by_builder(items : Array[String], sep : String) -> String {
  if items.length() == 0 {
    return ""
  }
  let b = StringBuilder::new()
  b.write_string(items[0])
  for i = 1; i < items.length(); i = i + 1 {
    b.write_string(sep)
    b.write_string(items[i])
  }
  b.to_string()
}

///|
fn bench_join_by_builder(b: @bench.B) {
  let items = []
  for i = 0; i < 1000; i = i + 1 {
    items.push("item" + i.to_string())
  }
  b.run("join_by_builder", fn() {
    let _ = join_by_builder(items, ",")
  })
}
