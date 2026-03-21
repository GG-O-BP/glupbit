//// Withdrawal — `POST /withdraws/coin`, `POST /withdraws/krw`.

import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}

import glupbit/client
import glupbit/types

/// Digital asset withdrawal request.
pub type CoinWithdrawRequest {
  CoinWithdrawRequest(
    currency: String,
    net_type: String,
    amount: String,
    address: String,
    secondary_address: Option(String),
    transaction_type: Option(String),
  )
}

/// KRW withdrawal request.
pub type KrwWithdrawRequest {
  KrwWithdrawRequest(amount: String, two_factor_type: Option(String))
}

/// Withdrawal response.
pub type WithdrawResponse {
  WithdrawResponse(
    uuid: String,
    currency: String,
    net_type: Option(String),
    txid: Option(String),
    state: String,
    created_at: String,
    amount: String,
    fee: String,
    transaction_type: String,
  )
}

/// Withdraw digital assets. `POST /withdraws/coin`
pub fn withdraw_coin(
  c: client.AuthClient,
  req req: CoinWithdrawRequest,
) -> Result(types.ApiResponse(WithdrawResponse), types.ApiError) {
  let pairs =
    [
      Some(#("currency", req.currency)),
      Some(#("net_type", req.net_type)),
      Some(#("amount", req.amount)),
      Some(#("address", req.address)),
      req.secondary_address |> option.map(fn(v) { #("secondary_address", v) }),
      req.transaction_type |> option.map(fn(v) { #("transaction_type", v) }),
    ]
    |> option.values
  post_withdraw(c, "/withdraws/coin", pairs)
}

/// Withdraw KRW. `POST /withdraws/krw`
pub fn withdraw_krw(
  c: client.AuthClient,
  req req: KrwWithdrawRequest,
) -> Result(types.ApiResponse(WithdrawResponse), types.ApiError) {
  let pairs =
    [
      Some(#("amount", req.amount)),
      req.two_factor_type |> option.map(fn(v) { #("two_factor_type", v) }),
    ]
    |> option.values
  post_withdraw(c, "/withdraws/krw", pairs)
}

fn post_withdraw(
  c: client.AuthClient,
  path: String,
  pairs: List(#(String, String)),
) -> Result(types.ApiResponse(WithdrawResponse), types.ApiError) {
  let body =
    pairs |> list.map(fn(p) { #(p.0, json.string(p.1)) }) |> json.object
  client.auth_post(
    c,
    path:,
    body:,
    body_params: pairs,
    decoder: withdraw_response_decoder(),
  )
}

/// Decoder for WithdrawResponse.
pub fn withdraw_response_decoder() -> decode.Decoder(WithdrawResponse) {
  use uuid <- decode.field("uuid", decode.string)
  use currency <- decode.field("currency", decode.string)
  use net_type <- decode.optional_field(
    "net_type",
    None,
    decode.optional(decode.string),
  )
  use txid <- decode.optional_field(
    "txid",
    None,
    decode.optional(decode.string),
  )
  use state <- decode.field("state", decode.string)
  use created_at <- decode.field("created_at", decode.string)
  use amount <- decode.field("amount", decode.string)
  use fee <- decode.field("fee", decode.string)
  use transaction_type <- decode.field("transaction_type", decode.string)
  decode.success(WithdrawResponse(
    uuid:,
    currency:,
    net_type:,
    txid:,
    state:,
    created_at:,
    amount:,
    fee:,
    transaction_type:,
  ))
}
