//// WebSocket subscription types, message builders, and response decoders.

import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}

import glupbit/types

/// WebSocket response format.
pub type WsFormat {
  Default
  Simple
  JsonList
  SimpleList
}

/// A subscription request.
pub type Subscription {
  TickerSub(
    codes: List(types.Market),
    is_only_snapshot: Bool,
    is_only_realtime: Bool,
  )
  TradeSub(
    codes: List(types.Market),
    is_only_snapshot: Bool,
    is_only_realtime: Bool,
  )
  OrderbookSub(
    codes: List(types.Market),
    level: Option(String),
    is_only_snapshot: Bool,
    is_only_realtime: Bool,
  )
  CandleSub(
    codes: List(types.Market),
    unit: String,
    is_only_snapshot: Bool,
    is_only_realtime: Bool,
  )
  MyOrderSub(codes: Option(List(types.Market)))
  MyAssetSub
}

/// Build a WebSocket subscription message as a JSON string.
/// Returns a JSON array: [{"ticket":"..."}, {"type":"ticker","codes":[...]}, ..., {"format":"DEFAULT"}]
pub fn build_subscription_message(
  ticket: String,
  subscriptions: List(Subscription),
  format: WsFormat,
) -> String {
  let ticket_obj = json.object([#("ticket", json.string(ticket))])
  let sub_objs = list.map(subscriptions, subscription_to_json)
  let format_obj =
    json.object([#("format", json.string(ws_format_to_string(format)))])
  let all = [ticket_obj, ..list.append(sub_objs, [format_obj])]
  json.to_string(json.preprocessed_array(all))
}

/// Build a LIST_SUBSCRIPTIONS request message as a JSON string.
pub fn build_list_subscriptions_message(ticket: String) -> String {
  let ticket_obj = json.object([#("ticket", json.string(ticket))])
  let method_obj = json.object([#("method", json.string("LIST_SUBSCRIPTIONS"))])
  json.to_string(json.preprocessed_array([ticket_obj, method_obj]))
}

fn ws_format_to_string(format: WsFormat) -> String {
  case format {
    Default -> "DEFAULT"
    Simple -> "SIMPLE"
    JsonList -> "JSON_LIST"
    SimpleList -> "SIMPLE_LIST"
  }
}

fn subscription_to_json(sub: Subscription) -> json.Json {
  case sub {
    TickerSub(codes:, is_only_snapshot:, is_only_realtime:) ->
      build_sub_json(
        "ticker",
        codes,
        None,
        None,
        is_only_snapshot,
        is_only_realtime,
      )
    TradeSub(codes:, is_only_snapshot:, is_only_realtime:) ->
      build_sub_json(
        "trade",
        codes,
        None,
        None,
        is_only_snapshot,
        is_only_realtime,
      )
    OrderbookSub(codes:, level:, is_only_snapshot:, is_only_realtime:) ->
      build_sub_json(
        "orderbook",
        codes,
        level,
        None,
        is_only_snapshot,
        is_only_realtime,
      )
    CandleSub(codes:, unit:, is_only_snapshot:, is_only_realtime:) ->
      build_sub_json(
        "candle." <> unit,
        codes,
        None,
        None,
        is_only_snapshot,
        is_only_realtime,
      )
    MyOrderSub(codes:) -> {
      let base = [#("type", json.string("myOrder"))]
      let fields = case codes {
        Some(c) -> [
          #(
            "codes",
            json.array(c, fn(m) { json.string(types.market_to_string(m)) }),
          ),
          ..base
        ]
        None -> base
      }
      json.object(fields)
    }
    MyAssetSub -> json.object([#("type", json.string("myAsset"))])
  }
}

fn build_sub_json(
  type_name: String,
  codes: List(types.Market),
  level: Option(String),
  _extra: Option(String),
  is_only_snapshot: Bool,
  is_only_realtime: Bool,
) -> json.Json {
  let fields = [
    #("type", json.string(type_name)),
    #(
      "codes",
      json.array(codes, fn(m) { json.string(types.market_to_string(m)) }),
    ),
  ]
  let fields = case level {
    Some(l) -> [#("level", json.string(l)), ..fields]
    None -> fields
  }
  let fields = case is_only_snapshot {
    True -> [#("isOnlySnapshot", json.bool(True)), ..fields]
    False -> fields
  }
  let fields = case is_only_realtime {
    True -> [#("isOnlyRealtime", json.bool(True)), ..fields]
    False -> fields
  }
  json.object(fields)
}

// --- WebSocket response data types ---

/// Real-time ticker data from WebSocket.
pub type TickerData {
  TickerData(
    code: String,
    trade_price: Float,
    change: String,
    signed_change_rate: Float,
    acc_trade_volume_24h: Float,
    timestamp: Int,
  )
}

/// Real-time trade data from WebSocket.
pub type TradeData {
  TradeData(
    code: String,
    trade_price: Float,
    trade_volume: Float,
    ask_bid: String,
    trade_timestamp: Int,
    sequential_id: Int,
  )
}

/// Real-time orderbook data from WebSocket.
pub type OrderbookData {
  OrderbookData(
    code: String,
    total_ask_size: Float,
    total_bid_size: Float,
    timestamp: Int,
  )
}

// --- Decoders for WebSocket data ---

/// Decoder for WebSocket ticker data.
pub fn ticker_data_decoder() -> decode.Decoder(TickerData) {
  use code <- decode.field("code", decode.string)
  use trade_price <- decode.field("trade_price", decode.float)
  use change <- decode.field("change", decode.string)
  use signed_change_rate <- decode.field("signed_change_rate", decode.float)
  use acc_trade_volume_24h <- decode.field("acc_trade_volume_24h", decode.float)
  use timestamp <- decode.field("timestamp", decode.int)
  decode.success(TickerData(
    code:,
    trade_price:,
    change:,
    signed_change_rate:,
    acc_trade_volume_24h:,
    timestamp:,
  ))
}

/// Decoder for WebSocket trade data.
pub fn trade_data_decoder() -> decode.Decoder(TradeData) {
  use code <- decode.field("code", decode.string)
  use trade_price <- decode.field("trade_price", decode.float)
  use trade_volume <- decode.field("trade_volume", decode.float)
  use ask_bid <- decode.field("ask_bid", decode.string)
  use trade_timestamp <- decode.field("trade_timestamp", decode.int)
  use sequential_id <- decode.field("sequential_id", decode.int)
  decode.success(TradeData(
    code:,
    trade_price:,
    trade_volume:,
    ask_bid:,
    trade_timestamp:,
    sequential_id:,
  ))
}

/// Decoder for WebSocket orderbook data.
pub fn orderbook_data_decoder() -> decode.Decoder(OrderbookData) {
  use code <- decode.field("code", decode.string)
  use total_ask_size <- decode.field("total_ask_size", decode.float)
  use total_bid_size <- decode.field("total_bid_size", decode.float)
  use timestamp <- decode.field("timestamp", decode.int)
  decode.success(OrderbookData(
    code:,
    total_ask_size:,
    total_bid_size:,
    timestamp:,
  ))
}

// --- LIST_SUBSCRIPTIONS types ---

/// Information about a single active subscription.
pub type SubscriptionInfo {
  SubscriptionInfo(
    type_name: String,
    codes: Option(List(String)),
    level: Option(Float),
  )
}

/// Response from a LIST_SUBSCRIPTIONS query.
pub type ListSubscriptionsResponse {
  ListSubscriptionsResponse(
    method: String,
    result: List(SubscriptionInfo),
    ticket: String,
  )
}

/// Decoder for a single subscription info item.
pub fn subscription_info_decoder() -> decode.Decoder(SubscriptionInfo) {
  use type_name <- decode.field("type", decode.string)
  use codes <- decode.optional_field(
    "codes",
    None,
    decode.optional(decode.list(decode.string)),
  )
  use level <- decode.optional_field(
    "level",
    None,
    decode.optional(decode.float),
  )
  decode.success(SubscriptionInfo(type_name:, codes:, level:))
}

/// Decoder for the LIST_SUBSCRIPTIONS response message.
pub fn list_subscriptions_response_decoder() -> decode.Decoder(
  ListSubscriptionsResponse,
) {
  use method <- decode.field("method", decode.string)
  use result <- decode.field("result", decode.list(subscription_info_decoder()))
  use ticket <- decode.field("ticket", decode.string)
  decode.success(ListSubscriptionsResponse(method:, result:, ticket:))
}
