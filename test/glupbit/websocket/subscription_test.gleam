import gleam/json
import gleam/option.{None, Some}
import gleam/string

import glupbit/types
import glupbit/websocket/subscription

pub fn build_ticker_subscription_test() {
  let assert Ok(m) = types.market("KRW-BTC")
  let msg =
    subscription.build_subscription_message(
      "test-ticket",
      [
        subscription.TickerSub(
          codes: [m],
          is_only_snapshot: False,
          is_only_realtime: False,
        ),
      ],
      subscription.Default,
    )
  assert string.contains(msg, "\"ticket\":\"test-ticket\"")
  assert string.contains(msg, "\"type\":\"ticker\"")
  assert string.contains(msg, "\"KRW-BTC\"")
  assert string.contains(msg, "\"format\":\"DEFAULT\"")
}

pub fn build_multiple_subscriptions_test() {
  let assert Ok(m1) = types.market("KRW-BTC")
  let assert Ok(m2) = types.market("KRW-ETH")
  let msg =
    subscription.build_subscription_message(
      "ticket-123",
      [
        subscription.TradeSub(
          codes: [m1, m2],
          is_only_snapshot: False,
          is_only_realtime: False,
        ),
        subscription.OrderbookSub(
          codes: [m1],
          level: Some("0.01"),
          is_only_snapshot: False,
          is_only_realtime: False,
        ),
      ],
      subscription.Simple,
    )
  assert string.contains(msg, "\"type\":\"trade\"")
  assert string.contains(msg, "\"type\":\"orderbook\"")
  assert string.contains(msg, "\"format\":\"SIMPLE\"")
}

pub fn build_my_asset_subscription_test() {
  let msg =
    subscription.build_subscription_message(
      "priv-ticket",
      [subscription.MyAssetSub],
      subscription.Default,
    )
  assert string.contains(msg, "\"type\":\"myAsset\"")
}

pub fn build_candle_subscription_test() {
  let assert Ok(m) = types.market("KRW-BTC")
  let msg =
    subscription.build_subscription_message(
      "candle-ticket",
      [
        subscription.CandleSub(
          codes: [m],
          unit: "1m",
          is_only_snapshot: False,
          is_only_realtime: True,
        ),
      ],
      subscription.Default,
    )
  assert string.contains(msg, "\"type\":\"candle.1m\"")
  assert string.contains(msg, "\"isOnlyRealtime\":true")
}

pub fn decode_ticker_data_test() {
  let json_str =
    "{\"code\":\"KRW-BTC\",\"trade_price\":60000000.0,\"change\":\"RISE\",\"signed_change_rate\":0.05,\"acc_trade_volume_24h\":1234.5,\"timestamp\":1704067200000}"
  let assert Ok(data) = json.parse(json_str, subscription.ticker_data_decoder())
  assert data.code == "KRW-BTC"
  assert data.trade_price == 60_000_000.0
  assert data.change == "RISE"
}

pub fn decode_trade_data_test() {
  let json_str =
    "{\"code\":\"KRW-BTC\",\"trade_price\":60000000.0,\"trade_volume\":0.5,\"ask_bid\":\"BID\",\"trade_timestamp\":1704067200000,\"sequential_id\":123456}"
  let assert Ok(data) = json.parse(json_str, subscription.trade_data_decoder())
  assert data.code == "KRW-BTC"
  assert data.trade_volume == 0.5
  assert data.ask_bid == "BID"
}

pub fn decode_orderbook_data_test() {
  let json_str =
    "{\"code\":\"KRW-BTC\",\"total_ask_size\":10.5,\"total_bid_size\":12.3,\"timestamp\":1704067200000}"
  let assert Ok(data) =
    json.parse(json_str, subscription.orderbook_data_decoder())
  assert data.code == "KRW-BTC"
  assert data.total_ask_size == 10.5
  assert data.total_bid_size == 12.3
}

pub fn build_list_subscriptions_message_test() {
  let msg = subscription.build_list_subscriptions_message("test-ticket-ls")
  assert string.contains(msg, "\"ticket\":\"test-ticket-ls\"")
  assert string.contains(msg, "\"method\":\"LIST_SUBSCRIPTIONS\"")
}

pub fn decode_list_subscriptions_response_test() {
  let json_str =
    "{\"method\":\"LIST_SUBSCRIPTIONS\",\"result\":[{\"type\":\"ticker\",\"codes\":[\"KRW-BTC\",\"KRW-ETH\"]},{\"type\":\"orderbook\",\"codes\":[\"KRW-BTC\",\"KRW-ETH\"],\"level\":0.0}],\"ticket\":\"unique uuid\"}"
  let assert Ok(resp) =
    json.parse(json_str, subscription.list_subscriptions_response_decoder())
  assert resp.method == "LIST_SUBSCRIPTIONS"
  assert resp.ticket == "unique uuid"
  let assert [ticker_sub, orderbook_sub] = resp.result
  assert ticker_sub.type_name == "ticker"
  assert ticker_sub.codes == Some(["KRW-BTC", "KRW-ETH"])
  assert ticker_sub.level == None
  assert orderbook_sub.type_name == "orderbook"
  assert orderbook_sub.level == Some(0.0)
}

pub fn decode_list_subscriptions_exchange_test() {
  let json_str =
    "{\"method\":\"LIST_SUBSCRIPTIONS\",\"result\":[{\"type\":\"myAsset\"},{\"type\":\"myOrder\",\"codes\":[\"KRW-BTC\",\"KRW-ETH\"]}],\"ticket\":\"priv-ticket\"}"
  let assert Ok(resp) =
    json.parse(json_str, subscription.list_subscriptions_response_decoder())
  let assert [asset_sub, order_sub] = resp.result
  assert asset_sub.type_name == "myAsset"
  assert asset_sub.codes == None
  assert order_sub.type_name == "myOrder"
  assert order_sub.codes == Some(["KRW-BTC", "KRW-ETH"])
}
