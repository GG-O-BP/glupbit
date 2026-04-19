import gleam/bit_array

import glupbit/websocket/connection
import glupbit/websocket/subscription

pub fn binary_frame_status_decoded_test() {
  let bytes = bit_array.from_string("{\"status\":\"UP\"}")
  let assert Ok(text) = bit_array.to_string(bytes)
  let msg = connection.decode_ws_message(text)
  assert msg == connection.StatusMsg("UP")
}

pub fn binary_frame_ticker_decoded_test() {
  let payload =
    "{\"type\":\"ticker\",\"code\":\"KRW-BTC\","
    <> "\"trade_price\":112197000.0,\"change\":\"EVEN\","
    <> "\"signed_change_rate\":0.0,"
    <> "\"acc_trade_volume_24h\":1.0,"
    <> "\"timestamp\":1776580000000}"
  let bytes = bit_array.from_string(payload)
  let assert Ok(text) = bit_array.to_string(bytes)
  let msg = connection.decode_ws_message(text)
  let assert connection.TickerMsg(data) = msg
  assert data.code == "KRW-BTC"
  assert data.trade_price == 112_197_000.0
  assert data.change == "EVEN"
  assert data.timestamp == 1_776_580_000_000
  let _: subscription.TickerData = data
}

pub fn binary_frame_invalid_utf8_safe_test() {
  let bytes = <<0xFF, 0xFE, 0xFD>>
  let result = bit_array.to_string(bytes)
  let assert Error(_) = result
}
