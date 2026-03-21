//// Account balance inquiry — `GET /accounts`.

import gleam/dynamic/decode

import glupbit/client
import glupbit/types

/// Account balance for a single currency.
pub type AccountBalance {
  AccountBalance(
    currency: String,
    balance: String,
    locked: String,
    avg_buy_price: String,
    avg_buy_price_modified: Bool,
    unit_currency: String,
  )
}

/// Get account balances.
/// GET /accounts
pub fn get_balances(
  c: client.AuthClient,
) -> Result(types.ApiResponse(List(AccountBalance)), types.ApiError) {
  client.auth_get(
    c,
    path: "/accounts",
    query: [],
    decoder: decode.list(account_balance_decoder()),
  )
}

/// Decoder for account balance.
pub fn account_balance_decoder() -> decode.Decoder(AccountBalance) {
  use currency <- decode.field("currency", decode.string)
  use balance <- decode.field("balance", decode.string)
  use locked <- decode.field("locked", decode.string)
  use avg_buy_price <- decode.field("avg_buy_price", decode.string)
  use avg_buy_price_modified <- decode.field(
    "avg_buy_price_modified",
    decode.bool,
  )
  use unit_currency <- decode.field("unit_currency", decode.string)
  decode.success(AccountBalance(
    currency:,
    balance:,
    locked:,
    avg_buy_price:,
    avg_buy_price_modified:,
    unit_currency:,
  ))
}
