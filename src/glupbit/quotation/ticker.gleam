//// Current price snapshots — `GET /ticker` and `GET /ticker/all`.

import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/string

import glupbit/client
import glupbit/types

/// Decode a JSON number as Float, accepting both float and int values.
fn number() -> decode.Decoder(Float) {
  decode.one_of(decode.float, [decode.int |> decode.map(int.to_float)])
}

/// Current price snapshot for a trading pair.
pub type Ticker {
  Ticker(
    market: String,
    trade_date: String,
    trade_time: String,
    trade_date_kst: String,
    trade_time_kst: String,
    trade_timestamp: Int,
    opening_price: Float,
    high_price: Float,
    low_price: Float,
    trade_price: Float,
    prev_closing_price: Float,
    change: String,
    change_price: Float,
    change_rate: Float,
    signed_change_price: Float,
    signed_change_rate: Float,
    trade_volume: Float,
    acc_trade_price: Float,
    acc_trade_price_24h: Float,
    acc_trade_volume: Float,
    acc_trade_volume_24h: Float,
    highest_52_week_price: Float,
    highest_52_week_date: String,
    lowest_52_week_price: Float,
    lowest_52_week_date: String,
    timestamp: Int,
  )
}

/// Get tickers for specific trading pairs.
pub fn get_tickers(
  c: client.PublicClient,
  markets markets: List(types.Market),
) -> Result(types.ApiResponse(List(Ticker)), types.ApiError) {
  let codes = markets |> list.map(types.market_to_string) |> string.join(",")
  client.public_get(
    c,
    path: "/ticker",
    query: [#("markets", codes)],
    decoder: decode.list(ticker_decoder()),
  )
}

/// Get all tickers filtered by quote currency (e.g., `"KRW"`, `"BTC"`).
pub fn get_all_tickers(
  c: client.PublicClient,
  quote_currencies currencies: List(String),
) -> Result(types.ApiResponse(List(Ticker)), types.ApiError) {
  client.public_get(
    c,
    path: "/ticker/all",
    query: [#("quote_currencies", string.join(currencies, ","))],
    decoder: decode.list(ticker_decoder()),
  )
}

/// Decoder for a Ticker JSON object.
pub fn ticker_decoder() -> decode.Decoder(Ticker) {
  use market <- decode.field("market", decode.string)
  use trade_date <- decode.field("trade_date", decode.string)
  use trade_time <- decode.field("trade_time", decode.string)
  use trade_date_kst <- decode.field("trade_date_kst", decode.string)
  use trade_time_kst <- decode.field("trade_time_kst", decode.string)
  use trade_timestamp <- decode.field("trade_timestamp", decode.int)
  use opening_price <- decode.field("opening_price", number())
  use high_price <- decode.field("high_price", number())
  use low_price <- decode.field("low_price", number())
  use trade_price <- decode.field("trade_price", number())
  use prev_closing_price <- decode.field("prev_closing_price", number())
  use change <- decode.field("change", decode.string)
  use change_price <- decode.field("change_price", number())
  use change_rate <- decode.field("change_rate", number())
  use signed_change_price <- decode.field("signed_change_price", number())
  use signed_change_rate <- decode.field("signed_change_rate", number())
  use trade_volume <- decode.field("trade_volume", number())
  use acc_trade_price <- decode.field("acc_trade_price", number())
  use acc_trade_price_24h <- decode.field("acc_trade_price_24h", number())
  use acc_trade_volume <- decode.field("acc_trade_volume", number())
  use acc_trade_volume_24h <- decode.field("acc_trade_volume_24h", number())
  use highest_52_week_price <- decode.field("highest_52_week_price", number())
  use highest_52_week_date <- decode.field(
    "highest_52_week_date",
    decode.string,
  )
  use lowest_52_week_price <- decode.field("lowest_52_week_price", number())
  use lowest_52_week_date <- decode.field("lowest_52_week_date", decode.string)
  use timestamp <- decode.field("timestamp", decode.int)
  decode.success(Ticker(
    market:,
    trade_date:,
    trade_time:,
    trade_date_kst:,
    trade_time_kst:,
    trade_timestamp:,
    opening_price:,
    high_price:,
    low_price:,
    trade_price:,
    prev_closing_price:,
    change:,
    change_price:,
    change_rate:,
    signed_change_price:,
    signed_change_rate:,
    trade_volume:,
    acc_trade_price:,
    acc_trade_price_24h:,
    acc_trade_volume:,
    acc_trade_volume_24h:,
    highest_52_week_price:,
    highest_52_week_date:,
    lowest_52_week_price:,
    lowest_52_week_date:,
    timestamp:,
  ))
}
