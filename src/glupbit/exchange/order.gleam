//// Order management — create, query, cancel orders.

import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}

import glupbit/client
import glupbit/types

// --- Request types ---

/// Parameters for creating a new order.
pub type NewOrder {
  NewOrder(
    market: types.Market,
    side: types.OrderSide,
    ord_type: types.OrderType,
    volume: Option(String),
    price: Option(String),
    identifier: Option(String),
    time_in_force: Option(types.TimeInForce),
    smp_type: Option(types.SmpType),
  )
}

// --- Response types ---

/// Response from order creation.
pub type OrderResponse {
  OrderResponse(
    market: String,
    uuid: String,
    side: String,
    ord_type: String,
    price: Option(String),
    state: String,
    created_at: String,
    volume: Option(String),
    remaining_volume: Option(String),
    executed_volume: String,
    reserved_fee: String,
    remaining_fee: String,
    paid_fee: String,
    locked: String,
    trades_count: Int,
    time_in_force: Option(String),
    identifier: Option(String),
    smp_type: Option(String),
  )
}

/// Detailed order info, optionally including trade executions.
pub type OrderDetail {
  OrderDetail(
    market: String,
    uuid: String,
    side: String,
    ord_type: String,
    price: Option(String),
    state: String,
    created_at: String,
    volume: Option(String),
    remaining_volume: Option(String),
    executed_volume: String,
    trades_count: Int,
    trades: Option(List(TradeExecution)),
  )
}

/// A single fill within an order.
pub type TradeExecution {
  TradeExecution(
    market: String,
    uuid: String,
    price: String,
    volume: String,
    funds: String,
    created_at: String,
    side: String,
  )
}

/// Order constraints and account info for a market.
pub type OrderChance {
  OrderChance(
    bid_fee: String,
    ask_fee: String,
    market_id: String,
    bid_account_currency: String,
    bid_account_balance: String,
    ask_account_currency: String,
    ask_account_balance: String,
  )
}

// --- API functions ---

/// Create a new order. `POST /orders`
pub fn create_order(
  c: client.AuthClient,
  order order: NewOrder,
) -> Result(types.ApiResponse(OrderResponse), types.ApiError) {
  let #(body, params) = encode_order(order)
  client.auth_post(
    c,
    path: "/orders",
    body:,
    body_params: params,
    decoder: order_response_decoder(),
  )
}

/// Create a test order (no execution). `POST /orders/test`
pub fn test_order(
  c: client.AuthClient,
  order order: NewOrder,
) -> Result(types.ApiResponse(OrderResponse), types.ApiError) {
  let #(body, params) = encode_order(order)
  client.auth_post(
    c,
    path: "/orders/test",
    body:,
    body_params: params,
    decoder: order_response_decoder(),
  )
}

/// Get a single order by UUID. `GET /order`
pub fn get_order(
  c: client.AuthClient,
  uuid uuid: String,
) -> Result(types.ApiResponse(OrderDetail), types.ApiError) {
  client.auth_get(
    c,
    path: "/order",
    query: [#("uuid", uuid)],
    decoder: order_detail_decoder(),
  )
}

/// Get a single order by client identifier. `GET /order`
pub fn get_order_by_identifier(
  c: client.AuthClient,
  identifier id: String,
) -> Result(types.ApiResponse(OrderDetail), types.ApiError) {
  client.auth_get(
    c,
    path: "/order",
    query: [#("identifier", id)],
    decoder: order_detail_decoder(),
  )
}

/// List open orders. `GET /orders/open`
pub fn list_open_orders(
  c: client.AuthClient,
  market market: Option(types.Market),
  state state: Option(String),
) -> Result(types.ApiResponse(List(OrderDetail)), types.ApiError) {
  let query =
    [
      market |> option.map(fn(m) { #("market", types.market_to_string(m)) }),
      state |> option.map(fn(s) { #("state", s) }),
    ]
    |> option.values
  client.auth_get(
    c,
    path: "/orders/open",
    query:,
    decoder: decode.list(order_detail_decoder()),
  )
}

/// List closed orders. `GET /orders/closed`
pub fn list_closed_orders(
  c: client.AuthClient,
  market market: Option(types.Market),
  state state: Option(String),
  start_time start_time: Option(String),
  end_time end_time: Option(String),
  limit limit: Option(Int),
) -> Result(types.ApiResponse(List(OrderDetail)), types.ApiError) {
  let query =
    [
      market |> option.map(fn(m) { #("market", types.market_to_string(m)) }),
      state |> option.map(fn(s) { #("state", s) }),
      start_time |> option.map(fn(t) { #("start_time", t) }),
      end_time |> option.map(fn(t) { #("end_time", t) }),
      limit |> option.map(fn(n) { #("limit", int.to_string(n)) }),
    ]
    |> option.values
  client.auth_get(
    c,
    path: "/orders/closed",
    query:,
    decoder: decode.list(order_detail_decoder()),
  )
}

/// List orders by UUIDs. `GET /orders/uuids`
pub fn list_orders_by_uuids(
  c: client.AuthClient,
  uuids uuids: List(String),
) -> Result(types.ApiResponse(List(OrderDetail)), types.ApiError) {
  client.auth_get(
    c,
    path: "/orders/uuids",
    query: client.build_array_query(key: "uuids", values: uuids),
    decoder: decode.list(order_detail_decoder()),
  )
}

/// Cancel a single order by UUID. `DELETE /order`
pub fn cancel_order(
  c: client.AuthClient,
  uuid uuid: String,
) -> Result(types.ApiResponse(OrderDetail), types.ApiError) {
  client.auth_delete(
    c,
    path: "/order",
    query: [#("uuid", uuid)],
    decoder: order_detail_decoder(),
  )
}

/// Cancel a single order by identifier. `DELETE /order`
pub fn cancel_order_by_identifier(
  c: client.AuthClient,
  identifier id: String,
) -> Result(types.ApiResponse(OrderDetail), types.ApiError) {
  client.auth_delete(
    c,
    path: "/order",
    query: [#("identifier", id)],
    decoder: order_detail_decoder(),
  )
}

/// Cancel multiple orders by UUIDs. `DELETE /orders/uuids`
pub fn cancel_orders_by_uuids(
  c: client.AuthClient,
  uuids uuids: List(String),
) -> Result(types.ApiResponse(List(OrderDetail)), types.ApiError) {
  client.auth_delete(
    c,
    path: "/orders/uuids",
    query: client.build_array_query(key: "uuids", values: uuids),
    decoder: decode.list(order_detail_decoder()),
  )
}

/// Batch-cancel open orders. `DELETE /orders/open`
pub fn batch_cancel_orders(
  c: client.AuthClient,
  market market: Option(types.Market),
  side side: Option(types.OrderSide),
) -> Result(types.ApiResponse(List(OrderDetail)), types.ApiError) {
  let query =
    [
      market |> option.map(fn(m) { #("market", types.market_to_string(m)) }),
      side |> option.map(fn(s) { #("side", types.order_side_to_string(s)) }),
    ]
    |> option.values
  client.auth_delete(
    c,
    path: "/orders/open",
    query:,
    decoder: decode.list(order_detail_decoder()),
  )
}

/// Get order constraints for a market. `GET /orders/chance`
pub fn get_order_chance(
  c: client.AuthClient,
  market market: types.Market,
) -> Result(types.ApiResponse(OrderChance), types.ApiError) {
  client.auth_get(
    c,
    path: "/orders/chance",
    query: [#("market", types.market_to_string(market))],
    decoder: order_chance_decoder(),
  )
}

// --- JSON encoding ---

fn encode_order(order: NewOrder) -> #(json.Json, List(#(String, String))) {
  let market_str = types.market_to_string(order.market)
  let side_str = types.order_side_to_string(order.side)
  let ord_type_str = types.order_type_to_string(order.ord_type)

  let pairs =
    [
      Some(#("market", market_str)),
      Some(#("side", side_str)),
      Some(#("ord_type", ord_type_str)),
      order.volume |> option.map(fn(v) { #("volume", v) }),
      order.price |> option.map(fn(v) { #("price", v) }),
      order.identifier |> option.map(fn(v) { #("identifier", v) }),
      order.time_in_force
        |> option.map(fn(t) {
          #("time_in_force", types.time_in_force_to_string(t))
        }),
      order.smp_type
        |> option.map(fn(s) { #("smp_type", types.smp_type_to_string(s)) }),
    ]
    |> option.values

  let body =
    pairs |> list.map(fn(p) { #(p.0, json.string(p.1)) }) |> json.object
  #(body, pairs)
}

// --- Decoders ---

fn optional_string() -> decode.Decoder(Option(String)) {
  decode.optional(decode.string)
}

/// Decoder for OrderResponse.
pub fn order_response_decoder() -> decode.Decoder(OrderResponse) {
  use market <- decode.field("market", decode.string)
  use uuid <- decode.field("uuid", decode.string)
  use side <- decode.field("side", decode.string)
  use ord_type <- decode.field("ord_type", decode.string)
  use price <- decode.optional_field("price", None, optional_string())
  use state <- decode.field("state", decode.string)
  use created_at <- decode.field("created_at", decode.string)
  use volume <- decode.optional_field("volume", None, optional_string())
  use remaining_volume <- decode.optional_field(
    "remaining_volume",
    None,
    optional_string(),
  )
  use executed_volume <- decode.field("executed_volume", decode.string)
  use reserved_fee <- decode.field("reserved_fee", decode.string)
  use remaining_fee <- decode.field("remaining_fee", decode.string)
  use paid_fee <- decode.field("paid_fee", decode.string)
  use locked <- decode.field("locked", decode.string)
  use trades_count <- decode.field("trades_count", decode.int)
  use time_in_force <- decode.optional_field(
    "time_in_force",
    None,
    optional_string(),
  )
  use identifier <- decode.optional_field("identifier", None, optional_string())
  use smp_type <- decode.optional_field("smp_type", None, optional_string())
  decode.success(OrderResponse(
    market:,
    uuid:,
    side:,
    ord_type:,
    price:,
    state:,
    created_at:,
    volume:,
    remaining_volume:,
    executed_volume:,
    reserved_fee:,
    remaining_fee:,
    paid_fee:,
    locked:,
    trades_count:,
    time_in_force:,
    identifier:,
    smp_type:,
  ))
}

/// Decoder for OrderDetail.
pub fn order_detail_decoder() -> decode.Decoder(OrderDetail) {
  use market <- decode.field("market", decode.string)
  use uuid <- decode.field("uuid", decode.string)
  use side <- decode.field("side", decode.string)
  use ord_type <- decode.field("ord_type", decode.string)
  use price <- decode.optional_field("price", None, optional_string())
  use state <- decode.field("state", decode.string)
  use created_at <- decode.field("created_at", decode.string)
  use volume <- decode.optional_field("volume", None, optional_string())
  use remaining_volume <- decode.optional_field(
    "remaining_volume",
    None,
    optional_string(),
  )
  use executed_volume <- decode.field("executed_volume", decode.string)
  use trades_count <- decode.field("trades_count", decode.int)
  use trades <- decode.optional_field(
    "trades",
    None,
    decode.optional(decode.list(trade_execution_decoder())),
  )
  decode.success(OrderDetail(
    market:,
    uuid:,
    side:,
    ord_type:,
    price:,
    state:,
    created_at:,
    volume:,
    remaining_volume:,
    executed_volume:,
    trades_count:,
    trades:,
  ))
}

fn trade_execution_decoder() -> decode.Decoder(TradeExecution) {
  use market <- decode.field("market", decode.string)
  use uuid <- decode.field("uuid", decode.string)
  use price <- decode.field("price", decode.string)
  use volume <- decode.field("volume", decode.string)
  use funds <- decode.field("funds", decode.string)
  use created_at <- decode.field("created_at", decode.string)
  use side <- decode.field("side", decode.string)
  decode.success(TradeExecution(
    market:,
    uuid:,
    price:,
    volume:,
    funds:,
    created_at:,
    side:,
  ))
}

fn order_chance_decoder() -> decode.Decoder(OrderChance) {
  use bid_fee <- decode.field("bid_fee", decode.string)
  use ask_fee <- decode.field("ask_fee", decode.string)
  use market_id <- decode.subfield(["market", "id"], decode.string)
  use bid_account_currency <- decode.subfield(
    ["bid_account", "currency"],
    decode.string,
  )
  use bid_account_balance <- decode.subfield(
    ["bid_account", "balance"],
    decode.string,
  )
  use ask_account_currency <- decode.subfield(
    ["ask_account", "currency"],
    decode.string,
  )
  use ask_account_balance <- decode.subfield(
    ["ask_account", "balance"],
    decode.string,
  )
  decode.success(OrderChance(
    bid_fee:,
    ask_fee:,
    market_id:,
    bid_account_currency:,
    bid_account_balance:,
    ask_account_currency:,
    ask_account_balance:,
  ))
}
