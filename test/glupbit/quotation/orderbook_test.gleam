import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{None}

import glupbit/quotation/orderbook

pub fn decode_orderbook_test() {
  let json_str =
    "[{\"market\":\"KRW-BTC\",\"timestamp\":1704067200000,\"total_ask_size\":10.5,\"total_bid_size\":12.3,\"orderbook_units\":[{\"ask_price\":60100000.0,\"bid_price\":60000000.0,\"ask_size\":1.5,\"bid_size\":2.0},{\"ask_price\":60200000.0,\"bid_price\":59900000.0,\"ask_size\":0.8,\"bid_size\":1.2}]}]"
  let assert Ok([ob]) =
    json.parse(json_str, decode.list(orderbook.orderbook_decoder()))
  assert ob.market == "KRW-BTC"
  assert ob.total_ask_size == 10.5
  assert ob.total_bid_size == 12.3
  assert list.length(ob.orderbook_units) == 2
  assert ob.level == None
  let assert [first, ..] = ob.orderbook_units
  assert first.ask_price == 60_100_000.0
  assert first.bid_price == 60_000_000.0
}
