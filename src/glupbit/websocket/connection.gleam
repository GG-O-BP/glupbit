//// WebSocket connection management via stratus actors.
////
//// Handles public and private (authenticated) connections with automatic
//// message routing based on the `type` field in incoming JSON.

import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/http/request
import gleam/json
import gleam/result

import glupbit/auth
import glupbit/websocket/subscription
import stratus
import youid/uuid

// --- Constants ---

const ws_public_url = "wss://api.upbit.com/websocket/v1"

const ws_private_url = "wss://api.upbit.com/websocket/v1/private"

// --- Types ---

/// Decoded WebSocket message.
pub type WsMessage {
  TickerMsg(subscription.TickerData)
  TradeMsg(subscription.TradeData)
  OrderbookMsg(subscription.OrderbookData)
  StatusMsg(String)
  ErrorMsg(name: String, message: String)
  RawMsg(String)
}

/// User message type for the WebSocket actor.
pub type WsCommand {
  Subscribe(List(subscription.Subscription), subscription.WsFormat)
}

/// Internal WebSocket state.
pub type WsState(user_state) {
  WsState(
    on_message: fn(user_state, WsMessage) -> user_state,
    user_state: user_state,
  )
}

/// Handle returned from connecting to a WebSocket.
pub type WsHandle =
  Subject(stratus.InternalMessage(WsCommand))

// --- Public API ---

/// Connect to the public WebSocket.
pub fn connect_public(
  state user_state: user_state,
  on_message handler: fn(user_state, WsMessage) -> user_state,
) -> Result(WsHandle, stratus.InitializationError) {
  let assert Ok(req) = request.to(ws_public_url)
  start_ws(req, user_state, handler)
}

/// Connect to the private WebSocket with authentication.
pub fn connect_private(
  credentials creds: auth.Credentials,
  state user_state: user_state,
  on_message handler: fn(user_state, WsMessage) -> user_state,
) -> Result(WsHandle, stratus.InitializationError) {
  let assert Ok(req) = request.to(ws_private_url)
  let assert Ok(token) = auth.generate_token(creds)
  let req = request.set_header(req, "authorization", "Bearer " <> token)
  start_ws(req, user_state, handler)
}

/// Send a subscription request over the WebSocket.
pub fn subscribe(
  conn: WsHandle,
  subscriptions: List(subscription.Subscription),
  format: subscription.WsFormat,
) -> Nil {
  process.send(conn, stratus.to_user_message(Subscribe(subscriptions, format)))
}

// --- Internal ---

fn start_ws(
  req: request.Request(String),
  user_state: user_state,
  handler: fn(user_state, WsMessage) -> user_state,
) -> Result(WsHandle, stratus.InitializationError) {
  let initial_state = WsState(on_message: handler, user_state: user_state)

  stratus.new(request: req, state: initial_state)
  |> stratus.on_message(fn(state, msg, conn) {
    case msg {
      stratus.Text(text) -> {
        let ws_msg = decode_ws_message(text)
        let new_user_state = state.on_message(state.user_state, ws_msg)
        stratus.continue(WsState(..state, user_state: new_user_state))
      }
      stratus.Binary(_) -> stratus.continue(state)
      stratus.User(Subscribe(subs, format)) -> {
        let ticket = uuid.v4_string()
        let msg_text =
          subscription.build_subscription_message(ticket, subs, format)
        let _ = stratus.send_text_message(conn, msg_text)
        stratus.continue(state)
      }
    }
  })
  |> stratus.on_close(fn(_state, _reason) { Nil })
  |> stratus.start
  |> result.map(fn(started) { started.data })
}

fn decode_ws_message(text: String) -> WsMessage {
  case json.parse(text, status_decoder()) {
    Ok(status) -> StatusMsg(status)
    Error(_) ->
      case json.parse(text, error_decoder()) {
        Ok(#(name, message)) -> ErrorMsg(name, message)
        Error(_) ->
          case json.parse(text, type_field_decoder()) {
            Ok("ticker") ->
              case json.parse(text, subscription.ticker_data_decoder()) {
                Ok(data) -> TickerMsg(data)
                Error(_) -> RawMsg(text)
              }
            Ok("trade") ->
              case json.parse(text, subscription.trade_data_decoder()) {
                Ok(data) -> TradeMsg(data)
                Error(_) -> RawMsg(text)
              }
            Ok("orderbook") ->
              case json.parse(text, subscription.orderbook_data_decoder()) {
                Ok(data) -> OrderbookMsg(data)
                Error(_) -> RawMsg(text)
              }
            Ok(_) -> RawMsg(text)
            Error(_) -> RawMsg(text)
          }
      }
  }
}

fn status_decoder() -> decode.Decoder(String) {
  use status <- decode.field("status", decode.string)
  decode.success(status)
}

fn error_decoder() -> decode.Decoder(#(String, String)) {
  use name <- decode.subfield(["error", "name"], decode.string)
  use message <- decode.subfield(["error", "message"], decode.string)
  decode.success(#(name, message))
}

fn type_field_decoder() -> decode.Decoder(String) {
  use type_name <- decode.field("type", decode.string)
  decode.success(type_name)
}
