//// Trading pair listing — `GET /market/all`.

import gleam/dynamic/decode
import gleam/option.{type Option, None}

import glupbit/client
import glupbit/types

/// A trading pair listed on Upbit.
pub type TradingPair {
  TradingPair(
    market: String,
    korean_name: String,
    english_name: String,
    market_event: Option(MarketEvent),
  )
}

/// Market event warnings and caution indicators.
pub type MarketEvent {
  MarketEvent(warning: Bool, caution: MarketCaution)
}

/// Specific caution flags for a trading pair.
pub type MarketCaution {
  MarketCaution(
    price_fluctuations: Bool,
    trading_volume_soaring: Bool,
    deposit_amount_soaring: Bool,
    global_price_differences: Bool,
    concentration_of_small_accounts: Bool,
  )
}

/// List all trading pairs.
pub fn list_all(
  c: client.PublicClient,
) -> Result(types.ApiResponse(List(TradingPair)), types.ApiError) {
  client.public_get(c, path: "/market/all", query: [], decoder: list_decoder())
}

/// List all trading pairs with detailed market event info.
pub fn list_all_detailed(
  c: client.PublicClient,
) -> Result(types.ApiResponse(List(TradingPair)), types.ApiError) {
  client.public_get(
    c,
    path: "/market/all",
    query: [#("is_details", "true")],
    decoder: list_decoder(),
  )
}

fn list_decoder() -> decode.Decoder(List(TradingPair)) {
  decode.list(trading_pair_decoder())
}

/// Decoder for a TradingPair JSON object.
pub fn trading_pair_decoder() -> decode.Decoder(TradingPair) {
  use market <- decode.field("market", decode.string)
  use korean_name <- decode.field("korean_name", decode.string)
  use english_name <- decode.field("english_name", decode.string)
  use market_event <- decode.optional_field(
    "market_event",
    None,
    decode.optional(market_event_decoder()),
  )
  decode.success(TradingPair(
    market:,
    korean_name:,
    english_name:,
    market_event:,
  ))
}

fn market_event_decoder() -> decode.Decoder(MarketEvent) {
  use warning <- decode.field("warning", decode.bool)
  use caution <- decode.field("caution", market_caution_decoder())
  decode.success(MarketEvent(warning:, caution:))
}

fn market_caution_decoder() -> decode.Decoder(MarketCaution) {
  use price_fluctuations <- decode.field("PRICE_FLUCTUATIONS", decode.bool)
  use trading_volume_soaring <- decode.field(
    "TRADING_VOLUME_SOARING",
    decode.bool,
  )
  use deposit_amount_soaring <- decode.field(
    "DEPOSIT_AMOUNT_SOARING",
    decode.bool,
  )
  use global_price_differences <- decode.field(
    "GLOBAL_PRICE_DIFFERENCES",
    decode.bool,
  )
  use concentration_of_small_accounts <- decode.field(
    "CONCENTRATION_OF_SMALL_ACCOUNTS",
    decode.bool,
  )
  decode.success(MarketCaution(
    price_fluctuations:,
    trading_volume_soaring:,
    deposit_amount_soaring:,
    global_price_differences:,
    concentration_of_small_accounts:,
  ))
}
