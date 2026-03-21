//// Shared domain types for the Glupbit Upbit API client.
////
//// Contains market identifiers, order enums, error types, and the
//// `ApiResponse` wrapper used by all API call functions.

import gleam/dynamic/decode
import gleam/httpc
import gleam/option.{type Option}
import gleam/string

// --- Market ---

/// Opaque trading pair identifier (e.g., `"KRW-BTC"`, `"BTC-ETH"`).
///
/// Construct via `market/1`; the raw string is only accessible
/// through `market_to_string/1`.
pub opaque type Market {
  Market(String)
}

/// Create a Market, validating `"QUOTE-BASE"` format.
pub fn market(code: String) -> Result(Market, Nil) {
  case string.split(code, "-") {
    [quote, base] if quote != "" && base != "" -> Ok(Market(code))
    _ -> Error(Nil)
  }
}

/// Convert a Market back to its string code.
pub fn market_to_string(m: Market) -> String {
  let Market(code) = m
  code
}

/// Decode a Market from a JSON string field.
pub fn market_decoder() -> decode.Decoder(Market) {
  decode.string |> decode.map(Market)
}

// --- Order Side ---

/// Order direction: buy (`Bid`) or sell (`Ask`).
pub type OrderSide {
  Bid
  Ask
}

pub fn order_side_to_string(side: OrderSide) -> String {
  case side {
    Bid -> "bid"
    Ask -> "ask"
  }
}

pub fn order_side_from_string(s: String) -> Result(OrderSide, Nil) {
  case s {
    "bid" -> Ok(Bid)
    "ask" -> Ok(Ask)
    _ -> Error(Nil)
  }
}

// --- Order Type ---

/// Order type determines matching behaviour.
pub type OrderType {
  Limit
  Price
  MarketSell
  Best
}

pub fn order_type_to_string(ord_type: OrderType) -> String {
  case ord_type {
    Limit -> "limit"
    Price -> "price"
    MarketSell -> "market"
    Best -> "best"
  }
}

pub fn order_type_from_string(s: String) -> Result(OrderType, Nil) {
  case s {
    "limit" -> Ok(Limit)
    "price" -> Ok(Price)
    "market" -> Ok(MarketSell)
    "best" -> Ok(Best)
    _ -> Error(Nil)
  }
}

// --- Order State ---

/// Lifecycle state of an order.
pub type OrderState {
  Wait
  Watch
  Done
  Cancel
}

pub fn order_state_to_string(state: OrderState) -> String {
  case state {
    Wait -> "wait"
    Watch -> "watch"
    Done -> "done"
    Cancel -> "cancel"
  }
}

pub fn order_state_from_string(s: String) -> Result(OrderState, Nil) {
  case s {
    "wait" -> Ok(Wait)
    "watch" -> Ok(Watch)
    "done" -> Ok(Done)
    "cancel" -> Ok(Cancel)
    _ -> Error(Nil)
  }
}

// --- Change ---

/// Price change direction.
pub type Change {
  Rise
  Even
  Fall
}

pub fn change_to_string(change: Change) -> String {
  case change {
    Rise -> "RISE"
    Even -> "EVEN"
    Fall -> "FALL"
  }
}

pub fn change_from_string(s: String) -> Result(Change, Nil) {
  case s {
    "RISE" -> Ok(Rise)
    "EVEN" -> Ok(Even)
    "FALL" -> Ok(Fall)
    _ -> Error(Nil)
  }
}

// --- Time In Force ---

/// Order execution condition.
pub type TimeInForce {
  Ioc
  Fok
  PostOnly
}

pub fn time_in_force_to_string(tif: TimeInForce) -> String {
  case tif {
    Ioc -> "ioc"
    Fok -> "fok"
    PostOnly -> "post_only"
  }
}

pub fn time_in_force_from_string(s: String) -> Result(TimeInForce, Nil) {
  case s {
    "ioc" -> Ok(Ioc)
    "fok" -> Ok(Fok)
    "post_only" -> Ok(PostOnly)
    _ -> Error(Nil)
  }
}

// --- SMP Type ---

/// Self-Match Prevention mode.
pub type SmpType {
  CancelMaker
  CancelTaker
  Reduce
}

pub fn smp_type_to_string(smp: SmpType) -> String {
  case smp {
    CancelMaker -> "cancel_maker"
    CancelTaker -> "cancel_taker"
    Reduce -> "reduce"
  }
}

pub fn smp_type_from_string(s: String) -> Result(SmpType, Nil) {
  case s {
    "cancel_maker" -> Ok(CancelMaker)
    "cancel_taker" -> Ok(CancelTaker)
    "reduce" -> Ok(Reduce)
    _ -> Error(Nil)
  }
}

// --- Rate Limit ---

/// Parsed `Remaining-Req` response header.
pub type RateLimit {
  RateLimit(group: String, remaining_min: Int, remaining_sec: Int)
}

// --- API Error ---

/// Unified error type for every API operation.
pub type ApiError {
  HttpError(httpc.HttpError)
  UpbitError(status: Int, name: String, message: String)
  DecodeError(List(decode.DecodeError))
  RateLimited(RateLimit)
  AuthError(String)
}

// --- API Response ---

/// Every successful API call returns data together with optional rate-limit
/// information extracted from the `Remaining-Req` header.
pub type ApiResponse(a) {
  ApiResponse(data: a, rate_limit: Option(RateLimit))
}
