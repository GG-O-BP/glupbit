//// OHLCV candle data — seconds, minutes, days, weeks, months, years.

import gleam/dynamic/decode
import gleam/int
import gleam/option.{type Option, None, Some}

import glupbit/client
import glupbit/types

/// Minute candle unit.
pub type MinuteUnit {
  Min1
  Min3
  Min5
  Min10
  Min15
  Min30
  Min60
  Min240
}

/// OHLCV candle data.
pub type Candle {
  Candle(
    market: String,
    candle_date_time_utc: String,
    candle_date_time_kst: String,
    opening_price: Float,
    high_price: Float,
    low_price: Float,
    trade_price: Float,
    timestamp: Int,
    candle_acc_trade_price: Float,
    candle_acc_trade_volume: Float,
    prev_closing_price: Option(Float),
    change_price: Option(Float),
    change_rate: Option(Float),
    converted_trade_price: Option(Float),
    unit: Option(Int),
  )
}

/// `GET /candles/seconds`
pub fn get_seconds(
  c: client.PublicClient,
  market market: types.Market,
  to to: Option(String),
  count count: Option(Int),
) -> Result(types.ApiResponse(List(Candle)), types.ApiError) {
  fetch(c, "/candles/seconds", market, to, count)
}

/// `GET /candles/minutes/{unit}`
pub fn get_minutes(
  c: client.PublicClient,
  unit unit: MinuteUnit,
  market market: types.Market,
  to to: Option(String),
  count count: Option(Int),
) -> Result(types.ApiResponse(List(Candle)), types.ApiError) {
  fetch(
    c,
    "/candles/minutes/" <> minute_unit_to_string(unit),
    market,
    to,
    count,
  )
}

/// `GET /candles/days`
pub fn get_days(
  c: client.PublicClient,
  market market: types.Market,
  to to: Option(String),
  count count: Option(Int),
) -> Result(types.ApiResponse(List(Candle)), types.ApiError) {
  fetch(c, "/candles/days", market, to, count)
}

/// `GET /candles/weeks`
pub fn get_weeks(
  c: client.PublicClient,
  market market: types.Market,
  to to: Option(String),
  count count: Option(Int),
) -> Result(types.ApiResponse(List(Candle)), types.ApiError) {
  fetch(c, "/candles/weeks", market, to, count)
}

/// `GET /candles/months`
pub fn get_months(
  c: client.PublicClient,
  market market: types.Market,
  to to: Option(String),
  count count: Option(Int),
) -> Result(types.ApiResponse(List(Candle)), types.ApiError) {
  fetch(c, "/candles/months", market, to, count)
}

/// `GET /candles/years`
pub fn get_years(
  c: client.PublicClient,
  market market: types.Market,
  to to: Option(String),
  count count: Option(Int),
) -> Result(types.ApiResponse(List(Candle)), types.ApiError) {
  fetch(c, "/candles/years", market, to, count)
}

// --- Internal ---

fn fetch(
  c: client.PublicClient,
  path: String,
  market: types.Market,
  to: Option(String),
  count: Option(Int),
) -> Result(types.ApiResponse(List(Candle)), types.ApiError) {
  client.public_get(
    c,
    path:,
    query: build_query(market, to, count),
    decoder: decode.list(candle_decoder()),
  )
}

fn minute_unit_to_string(unit: MinuteUnit) -> String {
  case unit {
    Min1 -> "1"
    Min3 -> "3"
    Min5 -> "5"
    Min10 -> "10"
    Min15 -> "15"
    Min30 -> "30"
    Min60 -> "60"
    Min240 -> "240"
  }
}

fn build_query(
  market: types.Market,
  to: Option(String),
  count: Option(Int),
) -> List(#(String, String)) {
  [
    Some(#("market", types.market_to_string(market))),
    to |> option.map(fn(t) { #("to", t) }),
    count |> option.map(fn(c) { #("count", int.to_string(c)) }),
  ]
  |> option.values
}

/// Decoder for Candle JSON object.
pub fn candle_decoder() -> decode.Decoder(Candle) {
  use market <- decode.field("market", decode.string)
  use candle_date_time_utc <- decode.field(
    "candle_date_time_utc",
    decode.string,
  )
  use candle_date_time_kst <- decode.field(
    "candle_date_time_kst",
    decode.string,
  )
  use opening_price <- decode.field("opening_price", decode.float)
  use high_price <- decode.field("high_price", decode.float)
  use low_price <- decode.field("low_price", decode.float)
  use trade_price <- decode.field("trade_price", decode.float)
  use timestamp <- decode.field("timestamp", decode.int)
  use candle_acc_trade_price <- decode.field(
    "candle_acc_trade_price",
    decode.float,
  )
  use candle_acc_trade_volume <- decode.field(
    "candle_acc_trade_volume",
    decode.float,
  )
  use prev_closing_price <- decode.optional_field(
    "prev_closing_price",
    None,
    decode.optional(decode.float),
  )
  use change_price <- decode.optional_field(
    "change_price",
    None,
    decode.optional(decode.float),
  )
  use change_rate <- decode.optional_field(
    "change_rate",
    None,
    decode.optional(decode.float),
  )
  use converted_trade_price <- decode.optional_field(
    "converted_trade_price",
    None,
    decode.optional(decode.float),
  )
  use unit <- decode.optional_field("unit", None, decode.optional(decode.int))
  decode.success(Candle(
    market:,
    candle_date_time_utc:,
    candle_date_time_kst:,
    opening_price:,
    high_price:,
    low_price:,
    trade_price:,
    timestamp:,
    candle_acc_trade_price:,
    candle_acc_trade_volume:,
    prev_closing_price:,
    change_price:,
    change_rate:,
    converted_trade_price:,
    unit:,
  ))
}
