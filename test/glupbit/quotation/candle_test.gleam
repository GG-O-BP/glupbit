import gleam/dynamic/decode
import gleam/json
import gleam/option.{None, Some}

import glupbit/quotation/candle

pub fn decode_day_candle_test() {
  let json_str =
    "[{\"market\":\"KRW-BTC\",\"candle_date_time_utc\":\"2024-01-01T00:00:00\",\"candle_date_time_kst\":\"2024-01-01T09:00:00\",\"opening_price\":60000000.0,\"high_price\":61000000.0,\"low_price\":59000000.0,\"trade_price\":60500000.0,\"timestamp\":1704067200000,\"candle_acc_trade_price\":1000000000.0,\"candle_acc_trade_volume\":16.5,\"prev_closing_price\":59500000.0,\"change_price\":1000000.0,\"change_rate\":0.0168}]"
  let assert Ok([c]) =
    json.parse(json_str, decode.list(candle.candle_decoder()))
  assert c.market == "KRW-BTC"
  assert c.opening_price == 60_000_000.0
  assert c.high_price == 61_000_000.0
  let assert Some(prev) = c.prev_closing_price
  assert prev == 59_500_000.0
  assert c.unit == None
}

pub fn decode_minute_candle_test() {
  let json_str =
    "[{\"market\":\"KRW-BTC\",\"candle_date_time_utc\":\"2024-01-01T00:05:00\",\"candle_date_time_kst\":\"2024-01-01T09:05:00\",\"opening_price\":60000000.0,\"high_price\":60100000.0,\"low_price\":59900000.0,\"trade_price\":60050000.0,\"timestamp\":1704067500000,\"candle_acc_trade_price\":50000000.0,\"candle_acc_trade_volume\":0.83,\"unit\":5}]"
  let assert Ok([c]) =
    json.parse(json_str, decode.list(candle.candle_decoder()))
  assert c.market == "KRW-BTC"
  let assert Some(5) = c.unit
}
