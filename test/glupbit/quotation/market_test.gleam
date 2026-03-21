import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{None, Some}

import glupbit/quotation/market

pub fn decode_trading_pair_test() {
  let json_str =
    "[{\"market\":\"KRW-BTC\",\"korean_name\":\"비트코인\",\"english_name\":\"Bitcoin\"}]"
  let assert Ok([pair]) =
    json.parse(json_str, decode.list(market.trading_pair_decoder()))
  assert pair.market == "KRW-BTC"
  assert pair.korean_name == "비트코인"
  assert pair.english_name == "Bitcoin"
  assert pair.market_event == None
}

pub fn decode_trading_pair_with_event_test() {
  let json_str =
    "[{\"market\":\"KRW-ETH\",\"korean_name\":\"이더리움\",\"english_name\":\"Ethereum\",\"market_event\":{\"warning\":true,\"caution\":{\"PRICE_FLUCTUATIONS\":false,\"TRADING_VOLUME_SOARING\":true,\"DEPOSIT_AMOUNT_SOARING\":false,\"GLOBAL_PRICE_DIFFERENCES\":false,\"CONCENTRATION_OF_SMALL_ACCOUNTS\":false}}}]"
  let assert Ok([pair]) =
    json.parse(json_str, decode.list(market.trading_pair_decoder()))
  assert pair.market == "KRW-ETH"
  let assert Some(event) = pair.market_event
  assert event.warning == True
  assert event.caution.trading_volume_soaring == True
  assert event.caution.price_fluctuations == False
}

pub fn decode_multiple_pairs_test() {
  let json_str =
    "[{\"market\":\"KRW-BTC\",\"korean_name\":\"비트코인\",\"english_name\":\"Bitcoin\"},{\"market\":\"KRW-ETH\",\"korean_name\":\"이더리움\",\"english_name\":\"Ethereum\"}]"
  let assert Ok(pairs) =
    json.parse(json_str, decode.list(market.trading_pair_decoder()))
  assert list.length(pairs) == 2
}
