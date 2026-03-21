import gleam/dynamic/decode
import gleam/json

import glupbit/quotation/trade

pub fn decode_trade_test() {
  let json_str =
    "[{\"market\":\"KRW-BTC\",\"trade_date_utc\":\"2024-01-01\",\"trade_time_utc\":\"12:00:00\",\"timestamp\":1704110400000,\"trade_price\":60000000.0,\"trade_volume\":0.5,\"prev_closing_price\":59500000.0,\"change_price\":500000.0,\"ask_bid\":\"BID\",\"sequential_id\":1704110400001}]"
  let assert Ok([t]) = json.parse(json_str, decode.list(trade.trade_decoder()))
  assert t.market == "KRW-BTC"
  assert t.trade_price == 60_000_000.0
  assert t.trade_volume == 0.5
  assert t.ask_bid == "BID"
  assert t.sequential_id == 1_704_110_400_001
}
