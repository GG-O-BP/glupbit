//// HTTP client infrastructure with two-tier authentication.
////
//// `PublicClient` — quotation (market data) endpoints, no auth needed.
//// `AuthClient`   — all endpoints including exchange (JWT required).
////
//// The Gleam type system statically prevents calling exchange endpoints
//// with a `PublicClient`.

import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

import glupbit/auth
import glupbit/types.{type ApiError, type ApiResponse, type RateLimit}

// --- Constants ---

const base_url = "https://api.upbit.com"

const default_timeout_ms = 30_000

// --- Client types ---

/// Public client — can only reach Quotation endpoints.
pub opaque type PublicClient {
  PublicClient(config: ClientConfig)
}

/// Authenticated client — can reach both Quotation and Exchange endpoints.
pub opaque type AuthClient {
  AuthClient(config: ClientConfig, credentials: auth.Credentials)
}

type ClientConfig {
  ClientConfig(base_url: String, http_config: httpc.Configuration)
}

// --- Constructors ---

/// Create a public client with default settings.
pub fn new_public() -> PublicClient {
  PublicClient(default_config())
}

/// Create an authenticated client.
pub fn new_auth(credentials credentials: auth.Credentials) -> AuthClient {
  AuthClient(config: default_config(), credentials:)
}

/// Create an authenticated client from environment variables.
pub fn new_auth_from_env() -> Result(AuthClient, String) {
  auth.credentials_from_env() |> result.map(new_auth)
}

/// Downcast an AuthClient to a PublicClient for quotation calls.
pub fn to_public(client: AuthClient) -> PublicClient {
  PublicClient(client.config)
}

fn default_config() -> ClientConfig {
  ClientConfig(
    base_url:,
    http_config: httpc.configure() |> httpc.timeout(default_timeout_ms),
  )
}

// --- Request execution ---

/// Execute a public GET request (no auth).
pub fn public_get(
  client: PublicClient,
  path path: String,
  query query: List(#(String, String)),
  decoder decoder: decode.Decoder(a),
) -> Result(ApiResponse(a), ApiError) {
  use req <- result.try(build_request(client.config, http.Get, path, query))
  execute(client.config, req, decoder)
}

/// Execute a public GET using an AuthClient.
pub fn public_get_auth(
  client: AuthClient,
  path path: String,
  query query: List(#(String, String)),
  decoder decoder: decode.Decoder(a),
) -> Result(ApiResponse(a), ApiError) {
  public_get(to_public(client), path:, query:, decoder:)
}

/// Execute an authenticated GET request.
pub fn auth_get(
  client: AuthClient,
  path path: String,
  query query: List(#(String, String)),
  decoder decoder: decode.Decoder(a),
) -> Result(ApiResponse(a), ApiError) {
  use req <- result.try(build_request(client.config, http.Get, path, query))
  use token <- result.try(auth_token_for_query(client.credentials, query))
  execute(client.config, req |> with_auth(token), decoder)
}

/// Execute an authenticated POST request with JSON body.
pub fn auth_post(
  client: AuthClient,
  path path: String,
  body body: json.Json,
  body_params params: List(#(String, String)),
  decoder decoder: decode.Decoder(a),
) -> Result(ApiResponse(a), ApiError) {
  use req <- result.try(build_request(client.config, http.Post, path, []))
  use token <- result.try(case params {
    [] -> auth.generate_token(client.credentials)
    _ -> auth.generate_token_with_body(client.credentials, body_params: params)
  })
  let req =
    req
    |> with_auth(token)
    |> request.set_header("content-type", "application/json; charset=utf-8")
    |> request.set_body(json.to_string(body))
  execute(client.config, req, decoder)
}

/// Execute an authenticated DELETE request.
pub fn auth_delete(
  client: AuthClient,
  path path: String,
  query query: List(#(String, String)),
  decoder decoder: decode.Decoder(a),
) -> Result(ApiResponse(a), ApiError) {
  use req <- result.try(build_request(client.config, http.Delete, path, query))
  use token <- result.try(auth_token_for_query(client.credentials, query))
  execute(client.config, req |> with_auth(token), decoder)
}

// --- Query helpers ---

/// Build `key[]=v1&key[]=v2` style query parameters.
pub fn build_array_query(
  key key: String,
  values values: List(String),
) -> List(#(String, String)) {
  let bracket_key = key <> "[]"
  list.map(values, fn(v) { #(bracket_key, v) })
}

/// Encode query parameters to a raw `key=value&...` string for hashing.
pub fn encode_query_string(query: List(#(String, String))) -> String {
  query
  |> list.map(fn(pair) { pair.0 <> "=" <> pair.1 })
  |> string.join("&")
}

/// Parse `"group=market; min=573; sec=9"` into a `RateLimit`.
pub fn parse_rate_limit_value(value: String) -> Option(RateLimit) {
  let parts =
    value
    |> string.split("; ")
    |> list.filter_map(fn(part) {
      case string.split(part, "=") {
        [key, val] -> Ok(#(string.trim(key), string.trim(val)))
        _ -> Error(Nil)
      }
    })

  let find = fn(key) {
    list.find(parts, fn(p) { p.0 == key }) |> result.map(fn(p) { p.1 })
  }

  case find("group") {
    Ok(group) ->
      Some(types.RateLimit(
        group:,
        remaining_min: find("min")
          |> result.try(int.parse)
          |> result.unwrap(0),
        remaining_sec: find("sec")
          |> result.try(int.parse)
          |> result.unwrap(0),
      ))
    Error(_) -> None
  }
}

// --- Internal ---

fn auth_token_for_query(
  credentials: auth.Credentials,
  query: List(#(String, String)),
) -> Result(String, ApiError) {
  case query {
    [] -> auth.generate_token(credentials)
    _ ->
      auth.generate_token_with_query(
        credentials,
        query_string: encode_query_string(query),
      )
  }
}

fn build_request(
  config: ClientConfig,
  method: http.Method,
  path: String,
  query: List(#(String, String)),
) -> Result(request.Request(String), ApiError) {
  let url = config.base_url <> "/v1" <> path
  use req <- result.try(
    request.to(url)
    |> result.replace_error(types.AuthError("Invalid URL: " <> url)),
  )
  let req = req |> request.set_method(method) |> set_accept_json
  case query {
    [] -> Ok(req)
    _ -> Ok(request.set_query(req, query))
  }
}

fn set_accept_json(req: request.Request(String)) -> request.Request(String) {
  request.set_header(req, "accept", "application/json")
}

fn with_auth(
  req: request.Request(String),
  token: String,
) -> request.Request(String) {
  request.set_header(req, "authorization", "Bearer " <> token)
}

fn execute(
  config: ClientConfig,
  req: request.Request(String),
  decoder: decode.Decoder(a),
) -> Result(ApiResponse(a), ApiError) {
  use resp <- result.try(
    httpc.dispatch(config.http_config, req)
    |> result.map_error(types.HttpError),
  )
  let rate_limit =
    response.get_header(resp, "remaining-req")
    |> result.map(parse_rate_limit_value)
    |> result.unwrap(None)

  case resp.status {
    200 | 201 ->
      json.parse(resp.body, decoder)
      |> result.map(fn(data) { types.ApiResponse(data:, rate_limit:) })
      |> result.map_error(json_decode_error)
    418 | 429 ->
      case rate_limit {
        Some(rl) -> Error(types.RateLimited(rl))
        None -> Error(types.UpbitError(resp.status, "rate_limited", ""))
      }
    status -> parse_error_body(status, resp.body)
  }
}

fn json_decode_error(err: json.DecodeError) -> ApiError {
  case err {
    json.UnableToDecode(errs) -> types.DecodeError(errs)
    json.UnexpectedByte(_)
    | json.UnexpectedEndOfInput
    | json.UnexpectedSequence(_) ->
      types.DecodeError([
        decode.DecodeError(expected: "valid JSON", found: "invalid", path: []),
      ])
  }
}

fn parse_error_body(status: Int, body: String) -> Result(a, ApiError) {
  // Upbit error name can be either a string or an int depending on the API tier
  let name_decoder =
    decode.one_of(decode.string, [decode.int |> decode.map(int.to_string)])
  let decoder = {
    use name <- decode.subfield(["error", "name"], name_decoder)
    use message <- decode.subfield(["error", "message"], decode.string)
    decode.success(#(name, message))
  }
  case json.parse(body, decoder) {
    Ok(#(name, message)) -> Error(types.UpbitError(status:, name:, message:))
    Error(_) -> Error(types.UpbitError(status:, name: "unknown", message: body))
  }
}
