import gleam/dynamic/decode
import gleam/json

import glupbit/exchange/account

pub fn decode_account_balance_test() {
  let json_str =
    "[{\"currency\":\"KRW\",\"balance\":\"1000000.0\",\"locked\":\"0.0\",\"avg_buy_price\":\"0\",\"avg_buy_price_modified\":false,\"unit_currency\":\"KRW\"},{\"currency\":\"BTC\",\"balance\":\"2.0\",\"locked\":\"0.0\",\"avg_buy_price\":\"140000000\",\"avg_buy_price_modified\":false,\"unit_currency\":\"KRW\"}]"
  let assert Ok(balances) =
    json.parse(json_str, decode.list(account.account_balance_decoder()))
  let assert [krw, btc] = balances
  assert krw.currency == "KRW"
  assert krw.balance == "1000000.0"
  assert krw.locked == "0.0"
  assert krw.avg_buy_price_modified == False
  assert btc.currency == "BTC"
  assert btc.balance == "2.0"
  assert btc.unit_currency == "KRW"
}
