//// Recent trade history — `GET /trades/ticks`.

import gleam/dynamic/decode
import gleam/int
import gleam/option.{type Option, Some}

import glupbit/client
import glupbit/types

/// A recent trade execution.
pub type Trade {
  Trade(
    market: String,
    trade_date_utc: String,
    trade_time_utc: String,
    timestamp: Int,
    trade_price: Float,
    trade_volume: Float,
    prev_closing_price: Float,
    change_price: Float,
    ask_bid: String,
    sequential_id: Int,
  )
}

/// Get recent trades for a market.
pub fn get_recent_trades(
  c: client.PublicClient,
  market market: types.Market,
  count count: Option(Int),
  to to: Option(String),
  cursor cursor: Option(String),
  days_ago days_ago: Option(Int),
) -> Result(types.ApiResponse(List(Trade)), types.ApiError) {
  let query =
    [
      Some(#("market", types.market_to_string(market))),
      count |> option.map(fn(n) { #("count", int.to_string(n)) }),
      to |> option.map(fn(t) { #("to", t) }),
      cursor |> option.map(fn(cur) { #("cursor", cur) }),
      days_ago |> option.map(fn(d) { #("daysAgo", int.to_string(d)) }),
    ]
    |> option.values
  client.public_get(
    c,
    path: "/trades/ticks",
    query:,
    decoder: decode.list(trade_decoder()),
  )
}

/// Decoder for a Trade JSON object.
pub fn trade_decoder() -> decode.Decoder(Trade) {
  use market <- decode.field("market", decode.string)
  use trade_date_utc <- decode.field("trade_date_utc", decode.string)
  use trade_time_utc <- decode.field("trade_time_utc", decode.string)
  use timestamp <- decode.field("timestamp", decode.int)
  use trade_price <- decode.field("trade_price", decode.float)
  use trade_volume <- decode.field("trade_volume", decode.float)
  use prev_closing_price <- decode.field("prev_closing_price", decode.float)
  use change_price <- decode.field("change_price", decode.float)
  use ask_bid <- decode.field("ask_bid", decode.string)
  use sequential_id <- decode.field("sequential_id", decode.int)
  decode.success(Trade(
    market:,
    trade_date_utc:,
    trade_time_utc:,
    timestamp:,
    trade_price:,
    trade_volume:,
    prev_closing_price:,
    change_price:,
    ask_bid:,
    sequential_id:,
  ))
}
