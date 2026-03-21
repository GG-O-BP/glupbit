# glupbit

[![Package Version](https://img.shields.io/hexpm/v/glupbit)](https://hex.pm/packages/glupbit)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glupbit/)

Upbit API를 Gleam으로 쓸 수 있게 해주는 라이브러리야~!
REST랑 WebSocket 둘 다 되고, 타입 시스템이 잘못된 호출을 막아주니까 안심이야!

## 설치하기

```sh
gleam add glupbit@1
```

이거 한 줄이면 끝이야! 진짜 쉽지?!

## 써보기

### Quotation (인증 안 해도 돼!)

```gleam
import gleam/io
import gleam/option.{None, Some}
import glupbit

pub fn main() {
  let client = glupbit.new()
  let assert Ok(market) = glupbit.market("KRW-BTC")

  // 거래 가능한 마켓 전부 가져오기
  let assert Ok(response) = glupbit.quotation.market.list_all(client)
  io.debug(response.data)

  // 비트코인 현재가 조회!
  let assert Ok(response) = glupbit.quotation.ticker.get_tickers(client, [market])
  io.debug(response.data)

  // 1분봉 캔들 10개 가져오기
  let assert Ok(response) =
    glupbit.quotation.candle.get_minutes(client, glupbit.quotation.candle.Min1, market, None, Some(10))
  io.debug(response.data)
}
```

### Exchange (잔고 조회, 주문 같은 거!)

```gleam
import gleam/io
import glupbit

pub fn main() {
  // 방법 1: key를 직접 넣어주기
  let creds =
    glupbit.credentials(
      glupbit.access_key("여기에-access-key"),
      glupbit.secret_key("여기에-secret-key"),
    )
  let client = glupbit.new_auth(creds)

  // 방법 2: 환경변수에서 읽어오기 (UPBIT_ACCESS_KEY, UPBIT_SECRET_KEY)
  let assert Ok(client) = glupbit.new_from_env()

  // 내 잔고 확인하기!
  let assert Ok(response) = glupbit.exchange.account.get_balances(client)
  io.debug(response.data)
}
```

### WebSocket (실시간 데이터!)

```gleam
import gleam/io
import gleam/option.{None}
import glupbit
import glupbit/websocket/connection
import glupbit/websocket/subscription.{TickerSub, Default}

pub fn main() {
  let assert Ok(market) = glupbit.market("KRW-BTC")

  let assert Ok(ws) =
    connection.connect_public(Nil, fn(_state, msg) {
      io.debug(msg)
      Nil
    })

  connection.subscribe(ws, [TickerSub([market], None, None)], Default)
}
```

실시간으로 시세가 쏟아져 나와!! 너무 신기하지 않아?!

## 할 수 있는 것들

### Quotation API (누구나 쓸 수 있어!)

| 모듈 | endpoint | 함수 |
|------|----------|------|
| `market` | `GET /market/all` | `list_all`, `list_all_detailed` |
| `ticker` | `GET /ticker` | `get_tickers`, `get_all_tickers` |
| `candle` | `GET /candles/*` | `get_seconds`, `get_minutes`, `get_days`, `get_weeks`, `get_months`, `get_years` |
| `trade` | `GET /trades/ticks` | `get_recent_trades` |
| `orderbook` | `GET /orderbook` | `get_orderbooks`, `get_supported_levels` |

### Exchange API (인증 필요해!)

| 모듈 | endpoint | 함수 |
|------|----------|------|
| `account` | `GET /accounts` | `get_balances` |
| `order` | `POST /orders` | `create_order`, `test_order` |
| `order` | `GET /order` | `get_order`, `get_order_by_identifier` |
| `order` | `GET /orders/open` | `list_open_orders` |
| `order` | `GET /orders/closed` | `list_closed_orders` |
| `order` | `DELETE /order` | `cancel_order`, `cancel_order_by_identifier` |
| `order` | `DELETE /orders/open` | `batch_cancel_orders` |
| `order` | `GET /orders/chance` | `get_order_chance` |
| `withdraw` | `POST /withdraws/coin` | `withdraw_coin` |
| `withdraw` | `POST /withdraws/krw` | `withdraw_krw` |
| `service` | `GET /status/wallet` | `get_wallet_status` |
| `service` | `GET /api_keys` | `list_api_keys` |
| `service` | Travel Rule | `list_travelrule_vasps`, `verify_travelrule_by_uuid`, `verify_travelrule_by_txid` |

### WebSocket (실시간!)

`connect_public`으로는 공개 데이터를, `connect_private`로는 내 주문이랑 내 자산을 실시간으로 볼 수 있어!

구독 종류: `TickerSub`, `TradeSub`, `OrderbookSub`, `CandleSub`, `MyOrderSub`, `MyAssetSub`

## 이 라이브러리의 좋은 점!

- **클라이언트가 두 종류야** — Quotation용 `PublicClient`랑 Exchange용 `AuthClient`가 따로 있어서, 인증 없이 Exchange API 부르는 실수는 컴파일러가 잡아줘!
- **전부 `Result`로 돌아와** — 에러가 나도 프로그램이 뻗지 않아! 안전해!
- **opaque type** — `Client`, `AccessKey`, `SecretKey`, `Market`을 함부로 못 만들어서 실수할 일이 없어!
- **rate limit 정보** — API 응답에 남은 요청 횟수가 같이 와!
- **JWT HS512 인증** — Upbit 스펙에 맞게 토큰이 자동으로 만들어져!

## 에러 처리

API 호출은 전부 `Result(ApiResponse(a), ApiError)`를 돌려줘! `ApiError` 종류는 이거야:

- `HttpError` — 네트워크 문제!
- `UpbitError` — Upbit에서 에러를 보냈어!
- `DecodeError` — JSON 파싱 실패!
- `RateLimited` — 요청을 너무 많이 보냈어! 좀 쉬어!
- `AuthError` — 인증 실패!

## 개발

```sh
gleam build           # 빌드하기
gleam test            # 테스트 돌리기
gleam format src test # 코드 예쁘게 정리하기
```

## 문서

자세한 API 문서는 [hexdocs.pm/glupbit](https://hexdocs.pm/glupbit)에 있어!

## 라이선스

[Blue Oak Model License 1.0.0](https://blueoakcouncil.org/license/1.0.0)
