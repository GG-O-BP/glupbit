//// Service information — wallet status, API keys, travel rule.

import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None}

import glupbit/client
import glupbit/types

/// Wallet service status for a currency.
pub type WalletStatus {
  WalletStatus(
    currency: String,
    wallet_state: String,
    block_state: String,
    block_height: Option(Int),
    block_updated_at: Option(String),
    block_elapsed_minutes: Option(Int),
  )
}

/// API key info.
pub type ApiKeyInfo {
  ApiKeyInfo(access_key: String, expire_at: String)
}

/// Travel rule VASP info.
pub type Vasp {
  Vasp(vasp_name: String, is_verified: Bool)
}

/// Travel rule verification result.
pub type TravelRuleResult {
  TravelRuleResult(is_verified: Bool)
}

/// Get wallet deposit/withdrawal service status.
/// GET /status/wallet
pub fn get_wallet_status(
  c: client.AuthClient,
) -> Result(types.ApiResponse(List(WalletStatus)), types.ApiError) {
  client.auth_get(c, "/status/wallet", [], decode.list(wallet_status_decoder()))
}

/// List API keys and their expiration dates.
/// GET /api_keys
pub fn list_api_keys(
  c: client.AuthClient,
) -> Result(types.ApiResponse(List(ApiKeyInfo)), types.ApiError) {
  client.auth_get(c, "/api_keys", [], decode.list(api_key_info_decoder()))
}

/// List travel rule VASPs.
/// GET /travel_rule/vasps
pub fn list_travelrule_vasps(
  c: client.AuthClient,
) -> Result(types.ApiResponse(List(Vasp)), types.ApiError) {
  client.auth_get(c, "/travel_rule/vasps", [], decode.list(vasp_decoder()))
}

/// Verify travel rule by deposit UUID.
/// POST /travel_rule/deposit/uuid
pub fn verify_travelrule_by_uuid(
  c: client.AuthClient,
  deposit_uuid: String,
  vasp_name: String,
) -> Result(types.ApiResponse(TravelRuleResult), types.ApiError) {
  let body =
    json.object([
      #("uuid", json.string(deposit_uuid)),
      #("vasp_name", json.string(vasp_name)),
    ])
  let params = [#("uuid", deposit_uuid), #("vasp_name", vasp_name)]
  client.auth_post(
    c,
    "/travel_rule/deposit/uuid",
    body,
    params,
    travelrule_result_decoder(),
  )
}

/// Verify travel rule by transaction ID.
/// POST /travel_rule/deposit/txid
pub fn verify_travelrule_by_txid(
  c: client.AuthClient,
  txid: String,
  currency: String,
  vasp_name: String,
) -> Result(types.ApiResponse(TravelRuleResult), types.ApiError) {
  let body =
    json.object([
      #("txid", json.string(txid)),
      #("currency", json.string(currency)),
      #("vasp_name", json.string(vasp_name)),
    ])
  let params = [
    #("txid", txid),
    #("currency", currency),
    #("vasp_name", vasp_name),
  ]
  client.auth_post(
    c,
    "/travel_rule/deposit/txid",
    body,
    params,
    travelrule_result_decoder(),
  )
}

// --- Decoders ---

fn wallet_status_decoder() -> decode.Decoder(WalletStatus) {
  use currency <- decode.field("currency", decode.string)
  use wallet_state <- decode.field("wallet_state", decode.string)
  use block_state <- decode.field("block_state", decode.string)
  use block_height <- decode.optional_field(
    "block_height",
    None,
    decode.optional(decode.int),
  )
  use block_updated_at <- decode.optional_field(
    "block_updated_at",
    None,
    decode.optional(decode.string),
  )
  use block_elapsed_minutes <- decode.optional_field(
    "block_elapsed_minutes",
    None,
    decode.optional(decode.int),
  )
  decode.success(WalletStatus(
    currency:,
    wallet_state:,
    block_state:,
    block_height:,
    block_updated_at:,
    block_elapsed_minutes:,
  ))
}

fn api_key_info_decoder() -> decode.Decoder(ApiKeyInfo) {
  use access_key <- decode.field("access_key", decode.string)
  use expire_at <- decode.field("expire_at", decode.string)
  decode.success(ApiKeyInfo(access_key:, expire_at:))
}

fn vasp_decoder() -> decode.Decoder(Vasp) {
  use vasp_name <- decode.field("vasp_name", decode.string)
  use is_verified <- decode.field("is_verified", decode.bool)
  decode.success(Vasp(vasp_name:, is_verified:))
}

fn travelrule_result_decoder() -> decode.Decoder(TravelRuleResult) {
  use is_verified <- decode.field("is_verified", decode.bool)
  decode.success(TravelRuleResult(is_verified:))
}
