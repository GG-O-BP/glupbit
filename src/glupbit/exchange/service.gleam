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
    block_state: Option(String),
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
  Vasp(
    vasp_name: String,
    vasp_uuid: String,
    depositable: Bool,
    withdrawable: Bool,
  )
}

/// Travel rule verification result.
pub type TravelRuleResult {
  TravelRuleResult(
    deposit_uuid: String,
    verification_result: String,
    deposit_state: String,
  )
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
  vasp_uuid: String,
) -> Result(types.ApiResponse(TravelRuleResult), types.ApiError) {
  let body =
    json.object([
      #("deposit_uuid", json.string(deposit_uuid)),
      #("vasp_uuid", json.string(vasp_uuid)),
    ])
  let params = [
    #("deposit_uuid", deposit_uuid),
    #("vasp_uuid", vasp_uuid),
  ]
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
  vasp_uuid: String,
  txid: String,
  currency: String,
  net_type: String,
) -> Result(types.ApiResponse(TravelRuleResult), types.ApiError) {
  let body =
    json.object([
      #("vasp_uuid", json.string(vasp_uuid)),
      #("txid", json.string(txid)),
      #("currency", json.string(currency)),
      #("net_type", json.string(net_type)),
    ])
  let params = [
    #("vasp_uuid", vasp_uuid),
    #("txid", txid),
    #("currency", currency),
    #("net_type", net_type),
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
  use block_state <- decode.optional_field(
    "block_state",
    None,
    decode.optional(decode.string),
  )
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
  use vasp_uuid <- decode.field("vasp_uuid", decode.string)
  use depositable <- decode.field("depositable", decode.bool)
  use withdrawable <- decode.field("withdrawable", decode.bool)
  decode.success(Vasp(vasp_name:, vasp_uuid:, depositable:, withdrawable:))
}

fn travelrule_result_decoder() -> decode.Decoder(TravelRuleResult) {
  use deposit_uuid <- decode.field("deposit_uuid", decode.string)
  use verification_result <- decode.field("verification_result", decode.string)
  use deposit_state <- decode.field("deposit_state", decode.string)
  decode.success(TravelRuleResult(
    deposit_uuid:,
    verification_result:,
    deposit_state:,
  ))
}
