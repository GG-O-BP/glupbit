//// WebSocket connection management via stratus actors.
////
//// Handles public and private (authenticated) connections with automatic
//// message routing based on `type` / `method` fields in incoming JSON.
//// Supports automatic reconnection with exponential backoff.

import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/float
import gleam/http/request
import gleam/int
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
  SubscriptionListMsg(subscription.ListSubscriptionsResponse)
  StatusMsg(String)
  ErrorMsg(name: String, message: String)
  RawMsg(String)
}

/// User message type for the WebSocket actor.
pub type WsCommand {
  Subscribe(List(subscription.Subscription), subscription.WsFormat)
  ListSubscriptions
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

/// Configuration for automatic WebSocket reconnection.
pub type ReconnectConfig {
  ReconnectConfig(
    subscriptions: List(subscription.Subscription),
    format: subscription.WsFormat,
    initial_delay_ms: Int,
    max_delay_ms: Int,
    on_reconnect: fn() -> Nil,
  )
}

// --- Public API ---

/// Connect to the public WebSocket.
pub fn connect_public(
  state user_state: user_state,
  on_message handler: fn(user_state, WsMessage) -> user_state,
) -> Result(WsHandle, stratus.InitializationError) {
  let assert Ok(req) = request.to(ws_public_url)
  start_ws(req, user_state, handler)
}

/// Connect to the public WebSocket with automatic reconnection.
/// On disconnect, retries with exponential backoff (1s, 2s, 4s, ... up to max_delay_ms).
/// Re-subscribes to the same feeds after successful reconnection.
pub fn connect_public_with_reconnect(
  state user_state: user_state,
  on_message handler: fn(user_state, WsMessage) -> user_state,
  reconnect config: ReconnectConfig,
) -> Result(WsHandle, stratus.InitializationError) {
  let assert Ok(req) = request.to(ws_public_url)
  start_ws_reconnectable(req, user_state, handler, config)
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

/// Query the list of active subscriptions on the WebSocket.
pub fn list_subscriptions(conn: WsHandle) -> Nil {
  process.send(conn, stratus.to_user_message(ListSubscriptions))
}

// --- Internal ---

fn start_ws(
  req: request.Request(String),
  user_state: user_state,
  handler: fn(user_state, WsMessage) -> user_state,
) -> Result(WsHandle, stratus.InitializationError) {
  let initial_state = WsState(on_message: handler, user_state: user_state)

  stratus.new(request: req, state: initial_state)
  |> stratus.on_message(ws_message_handler)
  |> stratus.on_close(fn(_state, _reason) { Nil })
  |> stratus.start
  |> result.map(fn(started) { started.data })
}

fn start_ws_reconnectable(
  req: request.Request(String),
  user_state: user_state,
  handler: fn(user_state, WsMessage) -> user_state,
  config: ReconnectConfig,
) -> Result(WsHandle, stratus.InitializationError) {
  let initial_state = WsState(on_message: handler, user_state: user_state)

  stratus.new(request: req, state: initial_state)
  |> stratus.on_message(ws_message_handler)
  |> stratus.on_close(fn(state, _reason) {
    // Spawn reconnection loop in a separate process
    let _ =
      erlang_spawn(fn() {
        reconnect_loop(
          req,
          state.user_state,
          state.on_message,
          config,
          config.initial_delay_ms,
        )
      })
    Nil
  })
  |> stratus.start
  |> result.map(fn(started) { started.data })
}

fn ws_message_handler(
  state: WsState(user_state),
  msg: stratus.Message(WsCommand),
  conn: stratus.Connection,
) -> stratus.Next(WsState(user_state), WsCommand) {
  case msg {
    stratus.Text(text) -> {
      let ws_msg = decode_ws_message(text)
      let new_user_state = state.on_message(state.user_state, ws_msg)
      stratus.continue(WsState(..state, user_state: new_user_state))
    }
    stratus.Binary(_) -> stratus.continue(state)
    stratus.User(cmd) -> {
      let msg_text = build_command_message(cmd)
      let _ = stratus.send_text_message(conn, msg_text)
      stratus.continue(state)
    }
  }
}

/// Exponential backoff reconnection loop.
/// Retries until successful, doubling delay each time up to max_delay_ms.
fn reconnect_loop(
  req: request.Request(String),
  user_state: user_state,
  handler: fn(user_state, WsMessage) -> user_state,
  config: ReconnectConfig,
  delay_ms: Int,
) -> Nil {
  log_info("[WS] Reconnecting in " <> int.to_string(delay_ms) <> "ms...")
  process.sleep(delay_ms)

  case start_ws_reconnectable(req, user_state, handler, config) {
    Ok(new_handle) -> {
      // Re-subscribe to feeds
      subscribe(new_handle, config.subscriptions, config.format)
      config.on_reconnect()
      log_info("[WS] Reconnected and re-subscribed")
    }
    Error(_) -> {
      // Exponential backoff: double delay, cap at max
      let next_delay =
        float.truncate(float.min(
          int.to_float(delay_ms * 2),
          int.to_float(config.max_delay_ms),
        ))
      log_info("[WS] Reconnection failed, retrying...")
      reconnect_loop(req, user_state, handler, config, next_delay)
    }
  }
}

@external(erlang, "erlang", "spawn")
fn erlang_spawn(f: fn() -> a) -> process.Pid

@external(erlang, "logger", "notice")
fn log_info(msg: String) -> Nil

fn build_command_message(cmd: WsCommand) -> String {
  let ticket = uuid.v4_string()
  case cmd {
    Subscribe(subs, format) ->
      subscription.build_subscription_message(ticket, subs, format)
    ListSubscriptions -> subscription.build_list_subscriptions_message(ticket)
  }
}

// --- Message decoding ---

fn decode_ws_message(text: String) -> WsMessage {
  case json.parse(text, field_decoder("status")) {
    Ok(status) -> StatusMsg(status)
    Error(_) ->
      case json.parse(text, error_decoder()) {
        Ok(#(name, message)) -> ErrorMsg(name, message)
        Error(_) -> decode_data_message(text)
      }
  }
}

fn decode_data_message(text: String) -> WsMessage {
  case json.parse(text, field_decoder("method")) {
    Ok("LIST_SUBSCRIPTIONS") ->
      try_decode(
        text,
        subscription.list_subscriptions_response_decoder(),
        SubscriptionListMsg,
      )
    Ok(_) -> RawMsg(text)
    Error(_) ->
      case json.parse(text, field_decoder("type")) {
        Ok(type_name) -> decode_by_type(text, type_name)
        Error(_) -> RawMsg(text)
      }
  }
}

fn decode_by_type(text: String, type_name: String) -> WsMessage {
  case type_name {
    "ticker" -> try_decode(text, subscription.ticker_data_decoder(), TickerMsg)
    "trade" -> try_decode(text, subscription.trade_data_decoder(), TradeMsg)
    "orderbook" ->
      try_decode(text, subscription.orderbook_data_decoder(), OrderbookMsg)
    _ -> RawMsg(text)
  }
}

fn try_decode(
  text: String,
  decoder: decode.Decoder(a),
  to_msg: fn(a) -> WsMessage,
) -> WsMessage {
  case json.parse(text, decoder) {
    Ok(data) -> to_msg(data)
    Error(_) -> RawMsg(text)
  }
}

fn field_decoder(name: String) -> decode.Decoder(String) {
  use value <- decode.field(name, decode.string)
  decode.success(value)
}

fn error_decoder() -> decode.Decoder(#(String, String)) {
  use name <- decode.subfield(["error", "name"], decode.string)
  use message <- decode.subfield(["error", "message"], decode.string)
  decode.success(#(name, message))
}
