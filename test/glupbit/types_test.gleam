import glupbit/types

pub fn market_valid_test() {
  let assert Ok(m) = types.market("KRW-BTC")
  assert types.market_to_string(m) == "KRW-BTC"
}

pub fn market_valid_btc_pair_test() {
  let assert Ok(m) = types.market("BTC-ETH")
  assert types.market_to_string(m) == "BTC-ETH"
}

pub fn market_invalid_no_hyphen_test() {
  let assert Error(Nil) = types.market("KRWBTC")
}

pub fn market_invalid_empty_parts_test() {
  let assert Error(Nil) = types.market("-BTC")
  let assert Error(Nil) = types.market("KRW-")
  let assert Error(Nil) = types.market("-")
}

pub fn market_invalid_multiple_hyphens_test() {
  let assert Error(Nil) = types.market("KRW-BTC-ETH")
}

pub fn order_side_roundtrip_test() {
  assert types.order_side_to_string(types.Bid) == "bid"
  assert types.order_side_to_string(types.Ask) == "ask"
  let assert Ok(types.Bid) = types.order_side_from_string("bid")
  let assert Ok(types.Ask) = types.order_side_from_string("ask")
  let assert Error(Nil) = types.order_side_from_string("invalid")
}

pub fn order_type_roundtrip_test() {
  assert types.order_type_to_string(types.Limit) == "limit"
  assert types.order_type_to_string(types.Price) == "price"
  assert types.order_type_to_string(types.MarketSell) == "market"
  assert types.order_type_to_string(types.Best) == "best"
  let assert Ok(types.Limit) = types.order_type_from_string("limit")
  let assert Ok(types.Price) = types.order_type_from_string("price")
  let assert Ok(types.MarketSell) = types.order_type_from_string("market")
  let assert Ok(types.Best) = types.order_type_from_string("best")
  let assert Error(Nil) = types.order_type_from_string("x")
}

pub fn order_state_roundtrip_test() {
  assert types.order_state_to_string(types.Wait) == "wait"
  assert types.order_state_to_string(types.Done) == "done"
  let assert Ok(types.Wait) = types.order_state_from_string("wait")
  let assert Ok(types.Watch) = types.order_state_from_string("watch")
  let assert Ok(types.Done) = types.order_state_from_string("done")
  let assert Ok(types.Cancel) = types.order_state_from_string("cancel")
  let assert Error(Nil) = types.order_state_from_string("x")
}

pub fn change_roundtrip_test() {
  assert types.change_to_string(types.Rise) == "RISE"
  assert types.change_to_string(types.Even) == "EVEN"
  assert types.change_to_string(types.Fall) == "FALL"
  let assert Ok(types.Rise) = types.change_from_string("RISE")
  let assert Ok(types.Even) = types.change_from_string("EVEN")
  let assert Ok(types.Fall) = types.change_from_string("FALL")
  let assert Error(Nil) = types.change_from_string("x")
}

pub fn time_in_force_roundtrip_test() {
  assert types.time_in_force_to_string(types.Ioc) == "ioc"
  assert types.time_in_force_to_string(types.Fok) == "fok"
  assert types.time_in_force_to_string(types.PostOnly) == "post_only"
  let assert Ok(types.Ioc) = types.time_in_force_from_string("ioc")
  let assert Ok(types.Fok) = types.time_in_force_from_string("fok")
  let assert Ok(types.PostOnly) = types.time_in_force_from_string("post_only")
  let assert Error(Nil) = types.time_in_force_from_string("x")
}

pub fn smp_type_roundtrip_test() {
  assert types.smp_type_to_string(types.CancelMaker) == "cancel_maker"
  assert types.smp_type_to_string(types.CancelTaker) == "cancel_taker"
  assert types.smp_type_to_string(types.Reduce) == "reduce"
  let assert Ok(types.CancelMaker) = types.smp_type_from_string("cancel_maker")
  let assert Ok(types.CancelTaker) = types.smp_type_from_string("cancel_taker")
  let assert Ok(types.Reduce) = types.smp_type_from_string("reduce")
  let assert Error(Nil) = types.smp_type_from_string("x")
}
