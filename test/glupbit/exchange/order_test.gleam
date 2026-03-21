import gleam/json
import gleam/option.{None, Some}

import glupbit/exchange/order

pub fn decode_order_response_test() {
  let json_str =
    "{\"market\":\"KRW-BTC\",\"uuid\":\"9ca023a5-851b-4fec-9f0a-48cd83c2eaae\",\"side\":\"ask\",\"ord_type\":\"limit\",\"price\":\"140000000\",\"state\":\"wait\",\"created_at\":\"2025-07-04T15:00:00+09:00\",\"volume\":\"1.0\",\"remaining_volume\":\"1.0\",\"executed_volume\":\"0.0\",\"reserved_fee\":\"70000.0\",\"remaining_fee\":\"70000.0\",\"paid_fee\":\"0.0\",\"locked\":\"0.0\",\"trades_count\":0,\"time_in_force\":\"ioc\",\"identifier\":\"9ca023a5-851b-4fec-9f0a-48cd83c2eaae\",\"smp_type\":\"cancel_maker\"}"
  let assert Ok(resp) = json.parse(json_str, order.order_response_decoder())
  assert resp.market == "KRW-BTC"
  assert resp.uuid == "9ca023a5-851b-4fec-9f0a-48cd83c2eaae"
  assert resp.side == "ask"
  assert resp.ord_type == "limit"
  assert resp.price == Some("140000000")
  assert resp.state == "wait"
  assert resp.trades_count == 0
  assert resp.time_in_force == Some("ioc")
  assert resp.smp_type == Some("cancel_maker")
}

pub fn decode_order_detail_test() {
  let json_str =
    "{\"market\":\"KRW-BTC\",\"uuid\":\"abc-123\",\"side\":\"bid\",\"ord_type\":\"limit\",\"price\":\"60000000\",\"state\":\"done\",\"created_at\":\"2024-01-01T00:00:00+09:00\",\"volume\":\"0.5\",\"remaining_volume\":\"0.0\",\"executed_volume\":\"0.5\",\"trades_count\":1,\"trades\":[{\"market\":\"KRW-BTC\",\"uuid\":\"trade-1\",\"price\":\"60000000\",\"volume\":\"0.5\",\"funds\":\"30000000\",\"created_at\":\"2024-01-01T00:00:01+09:00\",\"side\":\"bid\"}]}"
  let assert Ok(detail) = json.parse(json_str, order.order_detail_decoder())
  assert detail.market == "KRW-BTC"
  assert detail.state == "done"
  assert detail.executed_volume == "0.5"
  let assert Some(trades) = detail.trades
  let assert [trade] = trades
  assert trade.price == "60000000"
  assert trade.volume == "0.5"
  assert trade.funds == "30000000"
}

pub fn decode_order_detail_no_trades_test() {
  let json_str =
    "{\"market\":\"KRW-BTC\",\"uuid\":\"abc-456\",\"side\":\"ask\",\"ord_type\":\"limit\",\"state\":\"wait\",\"created_at\":\"2024-01-01T00:00:00+09:00\",\"volume\":\"1.0\",\"remaining_volume\":\"1.0\",\"executed_volume\":\"0.0\",\"trades_count\":0}"
  let assert Ok(detail) = json.parse(json_str, order.order_detail_decoder())
  assert detail.trades == None
  assert detail.price == None
}
