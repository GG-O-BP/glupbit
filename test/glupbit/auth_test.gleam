import gleam/bit_array
import gleam/list
import gleam/result
import gleam/string

import glupbit/auth

fn test_credentials() -> auth.Credentials {
  let ak = auth.access_key("test-access-key")
  // HS512 requires at least 64 bytes for the secret key
  let sk =
    auth.secret_key(
      "test-secret-key-that-is-at-least-64-bytes-long-for-hs512-signing!!",
    )
  auth.credentials(ak, sk)
}

pub fn sha512_hex_known_value_test() {
  let hash = auth.sha512_hex("")
  assert hash
    == "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e"
}

pub fn sha512_hex_query_string_test() {
  let hash = auth.sha512_hex("market=KRW-BTC&side=bid")
  assert string.length(hash) == 128
  assert string.lowercase(hash) == hash
}

pub fn generate_token_no_params_test() {
  let creds = test_credentials()
  let assert Ok(token) = auth.generate_token(creds)
  let parts = string.split(token, ".")
  assert list.length(parts) == 3
}

pub fn generate_token_with_query_test() {
  let creds = test_credentials()
  let assert Ok(token) =
    auth.generate_token_with_query(creds, "uuid=test-uuid-123")
  let parts = string.split(token, ".")
  assert list.length(parts) == 3
}

pub fn generate_token_with_body_test() {
  let creds = test_credentials()
  let assert Ok(token) =
    auth.generate_token_with_body(creds, [
      #("market", "KRW-BTC"),
      #("side", "bid"),
      #("ord_type", "limit"),
    ])
  let parts = string.split(token, ".")
  assert list.length(parts) == 3
}

pub fn generate_token_unique_nonce_test() {
  let creds = test_credentials()
  let assert Ok(token1) = auth.generate_token(creds)
  let assert Ok(token2) = auth.generate_token(creds)
  assert token1 != token2
}

pub fn jwt_header_is_hs512_test() {
  let creds = test_credentials()
  let assert Ok(token) = auth.generate_token(creds)
  let assert [header_b64, ..] = string.split(token, ".")
  let assert Ok(header_json) = decode_base64url(header_b64)
  assert string.contains(header_json, "\"alg\":\"HS512\"")
  assert string.contains(header_json, "\"typ\":\"JWT\"")
}

pub fn jwt_payload_contains_access_key_test() {
  let creds = test_credentials()
  let assert Ok(token) = auth.generate_token(creds)
  let assert [_, payload_b64, ..] = string.split(token, ".")
  let assert Ok(payload_json) = decode_base64url(payload_b64)
  assert string.contains(payload_json, "\"access_key\":\"test-access-key\"")
  assert string.contains(payload_json, "\"nonce\":")
}

pub fn jwt_payload_contains_query_hash_test() {
  let creds = test_credentials()
  let assert Ok(token) = auth.generate_token_with_query(creds, "market=KRW-BTC")
  let assert [_, payload_b64, ..] = string.split(token, ".")
  let assert Ok(payload_json) = decode_base64url(payload_b64)
  assert string.contains(payload_json, "\"query_hash\":")
  assert string.contains(payload_json, "\"query_hash_alg\":\"SHA512\"")
}

pub fn credentials_from_env_missing_test() {
  let assert Error(_) = auth.credentials_from_env()
}

fn decode_base64url(input: String) -> Result(String, Nil) {
  let padded = case string.length(input) % 4 {
    2 -> input <> "=="
    3 -> input <> "="
    _ -> input
  }
  let standard =
    padded
    |> string.replace("-", "+")
    |> string.replace("_", "/")
  use bits <- result.try(bit_array.base64_decode(standard))
  bit_array.to_string(bits)
  |> result.replace_error(Nil)
}
