///|
test "FileAppEnvelopeStore put and resolve" {
  let root = "/tmp/merkin-app-store-test"
  let store = @storage.FileAppEnvelopeStore::new(root)
  let record = @model.AppEnvelopeRecord::new(
    "app://mask/test-entry", "app/v1", "genius-loci", b"\xAA\xBB\xCC",
  )
  ignore(store.put(record))
  match store.resolve("app://mask/test-entry") {
    Some(resolved) => {
      @test.assert_eq(resolved.protocol, "app/v1")
      @test.assert_eq(resolved.audience, "genius-loci")
      @test.assert_eq(resolved.ciphertext_hash, record.ciphertext_hash)
      @test.assert_eq(resolved.ciphertext.length(), 3)
    }
    None => assert_true(false)
  }
}
