//// JWT HS512 authentication for Upbit Exchange API.
////
//// Generates signed tokens with `access_key`, `nonce`, and optional
//// `query_hash` / `query_hash_alg` claims using the **gose** JOSE library.

import envoy
import gleam/bit_array
import gleam/crypto
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import gose
import gose/jwa
import gose/jwk
import gose/jwt
import youid/uuid

import glupbit/types

// --- Opaque credential types ---

/// Upbit API Access Key.
pub opaque type AccessKey {
  AccessKey(String)
}

/// Upbit API Secret Key.
pub opaque type SecretKey {
  SecretKey(String)
}

/// Bundled access + secret key pair.
pub opaque type Credentials {
  Credentials(access_key: AccessKey, secret_key: SecretKey)
}

// --- Constructors ---

/// Wrap a raw string as an AccessKey.
pub fn access_key(key: String) -> AccessKey {
  AccessKey(key)
}

/// Wrap a raw string as a SecretKey.
pub fn secret_key(key: String) -> SecretKey {
  SecretKey(key)
}

/// Bundle an access key and secret key into Credentials.
pub fn credentials(ak: AccessKey, sk: SecretKey) -> Credentials {
  Credentials(access_key: ak, secret_key: sk)
}

/// Load credentials from `UPBIT_OPEN_API_ACCESS_KEY` and
/// `UPBIT_OPEN_API_SECRET_KEY` environment variables.
pub fn credentials_from_env() -> Result(Credentials, String) {
  use ak <- result.try(
    envoy.get("UPBIT_OPEN_API_ACCESS_KEY")
    |> result.replace_error("UPBIT_OPEN_API_ACCESS_KEY not set"),
  )
  use sk <- result.try(
    envoy.get("UPBIT_OPEN_API_SECRET_KEY")
    |> result.replace_error("UPBIT_OPEN_API_SECRET_KEY not set"),
  )
  Ok(credentials(AccessKey(ak), SecretKey(sk)))
}

// --- Token generation ---

/// Generate a JWT for requests **without** parameters.
pub fn generate_token(creds: Credentials) -> Result(String, types.ApiError) {
  sign_jwt(creds, [])
}

/// Generate a JWT for GET/DELETE requests **with** query parameters.
/// The raw `query_string` is SHA-512 hashed and included as `query_hash`.
pub fn generate_token_with_query(
  creds: Credentials,
  query_string query_string: String,
) -> Result(String, types.ApiError) {
  sign_jwt(creds, query_hash_claims(query_string))
}

/// Generate a JWT for POST requests with a JSON body.
/// Body params are converted to `key=value&...` format before hashing.
pub fn generate_token_with_body(
  creds: Credentials,
  body_params params: List(#(String, String)),
) -> Result(String, types.ApiError) {
  let query_string =
    params
    |> list.map(fn(pair) { pair.0 <> "=" <> pair.1 })
    |> string.join("&")
  sign_jwt(creds, query_hash_claims(query_string))
}

// --- Helpers ---

/// Compute the lowercase-hex SHA-512 digest of a string.
pub fn sha512_hex(input: String) -> String {
  input
  |> bit_array.from_string
  |> crypto.hash(crypto.Sha512, _)
  |> bit_array.base16_encode
  |> string.lowercase
}

fn query_hash_claims(query_string: String) -> List(#(String, json.Json)) {
  [
    #("query_hash", json.string(sha512_hex(query_string))),
    #("query_hash_alg", json.string("SHA512")),
  ]
}

/// Build, sign and serialize a JWT with HS512.
fn sign_jwt(
  creds: Credentials,
  extra_claims: List(#(String, json.Json)),
) -> Result(String, types.ApiError) {
  let Credentials(access_key: AccessKey(ak), secret_key: SecretKey(sk)) = creds

  use key <- result.try(
    sk
    |> bit_array.from_string
    |> jwk.from_octet_bits
    |> result.map_error(fn(e) {
      types.AuthError("JWK: " <> gose.error_message(e))
    }),
  )

  let base = [
    #("access_key", json.string(ak)),
    #("nonce", json.string(uuid.v4_string())),
  ]

  use claims <- result.try(
    list.append(base, extra_claims)
    |> list.try_fold(jwt.claims(), fn(claims, pair) {
      jwt.with_claim(claims, pair.0, pair.1)
      |> result.map_error(jwt_error_to_api_error)
    }),
  )

  use signed <- result.try(
    jwt.sign(jwa.JwsHmac(jwa.HmacSha256), claims, key)
    |> result.map_error(jwt_error_to_api_error),
  )

  Ok(jwt.serialize(signed))
}

fn jwt_error_to_api_error(err: jwt.JwtError) -> types.ApiError {
  types.AuthError("JWT: " <> string.inspect(err))
}
