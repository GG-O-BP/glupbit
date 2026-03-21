//// Orderbook snapshots — `GET /orderbook`, `/supported_levels`.

import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

import glupbit/client
import glupbit/types

/// Orderbook snapshot for a trading pair.
pub type Orderbook {
  Orderbook(
    market: String,
    timestamp: Int,
    total_ask_size: Float,
    total_bid_size: Float,
    orderbook_units: List(OrderbookUnit),
    level: Option(Float),
  )
}

/// A single price level in the orderbook.
pub type OrderbookUnit {
  OrderbookUnit(
    ask_price: Float,
    bid_price: Float,
    ask_size: Float,
    bid_size: Float,
  )
}

/// Supported orderbook grouping levels for a market.
pub type OrderbookLevel {
  OrderbookLevel(market: String, supported_levels: List(String))
}

/// Get orderbooks for trading pairs.
pub fn get_orderbooks(
  c: client.PublicClient,
  markets markets: List(types.Market),
  level level: Option(String),
  count count: Option(Int),
) -> Result(types.ApiResponse(List(Orderbook)), types.ApiError) {
  let codes = markets |> list.map(types.market_to_string) |> string.join(",")
  let query =
    [
      Some(#("markets", codes)),
      level |> option.map(fn(l) { #("level", l) }),
      count |> option.map(fn(n) { #("count", int.to_string(n)) }),
    ]
    |> option.values
  client.public_get(
    c,
    path: "/orderbook",
    query:,
    decoder: decode.list(orderbook_decoder()),
  )
}

/// Get supported orderbook levels.
pub fn get_supported_levels(
  c: client.PublicClient,
) -> Result(types.ApiResponse(List(OrderbookLevel)), types.ApiError) {
  client.public_get(
    c,
    path: "/orderbook/supported_levels",
    query: [],
    decoder: decode.list(orderbook_level_decoder()),
  )
}

/// Decoder for an Orderbook JSON object.
pub fn orderbook_decoder() -> decode.Decoder(Orderbook) {
  use market <- decode.field("market", decode.string)
  use timestamp <- decode.field("timestamp", decode.int)
  use total_ask_size <- decode.field("total_ask_size", decode.float)
  use total_bid_size <- decode.field("total_bid_size", decode.float)
  use orderbook_units <- decode.field(
    "orderbook_units",
    decode.list(orderbook_unit_decoder()),
  )
  use level <- decode.optional_field(
    "level",
    None,
    decode.optional(decode.float),
  )
  decode.success(Orderbook(
    market:,
    timestamp:,
    total_ask_size:,
    total_bid_size:,
    orderbook_units:,
    level:,
  ))
}

fn orderbook_unit_decoder() -> decode.Decoder(OrderbookUnit) {
  use ask_price <- decode.field("ask_price", decode.float)
  use bid_price <- decode.field("bid_price", decode.float)
  use ask_size <- decode.field("ask_size", decode.float)
  use bid_size <- decode.field("bid_size", decode.float)
  decode.success(OrderbookUnit(ask_price:, bid_price:, ask_size:, bid_size:))
}

fn orderbook_level_decoder() -> decode.Decoder(OrderbookLevel) {
  use market <- decode.field("market", decode.string)
  use supported_levels <- decode.field(
    "supported_levels",
    decode.list(decode.string),
  )
  decode.success(OrderbookLevel(market:, supported_levels:))
}
