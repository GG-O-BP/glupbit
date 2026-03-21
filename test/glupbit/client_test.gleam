import gleam/option.{None, Some}

import glupbit/client

pub fn parse_rate_limit_valid_test() {
  let assert Some(rl) =
    client.parse_rate_limit_value("group=market; min=573; sec=9")
  assert rl.group == "market"
  assert rl.remaining_min == 573
  assert rl.remaining_sec == 9
}

pub fn parse_rate_limit_exchange_test() {
  let assert Some(rl) =
    client.parse_rate_limit_value("group=default; min=1800; sec=29")
  assert rl.group == "default"
  assert rl.remaining_min == 1800
  assert rl.remaining_sec == 29
}

pub fn parse_rate_limit_invalid_test() {
  let assert None = client.parse_rate_limit_value("invalid")
  let assert None = client.parse_rate_limit_value("")
}

pub fn build_array_query_test() {
  let query = client.build_array_query("uuids", ["aaa", "bbb", "ccc"])
  assert query
    == [#("uuids[]", "aaa"), #("uuids[]", "bbb"), #("uuids[]", "ccc")]
}

pub fn build_array_query_empty_test() {
  let query = client.build_array_query("uuids", [])
  assert query == []
}

pub fn encode_query_string_test() {
  let qs =
    client.encode_query_string([#("market", "KRW-BTC"), #("side", "bid")])
  assert qs == "market=KRW-BTC&side=bid"
}

pub fn encode_query_string_empty_test() {
  let qs = client.encode_query_string([])
  assert qs == ""
}

pub fn encode_query_string_array_params_test() {
  let params = client.build_array_query("uuids", ["abc", "def"])
  let qs = client.encode_query_string(params)
  assert qs == "uuids[]=abc&uuids[]=def"
}
