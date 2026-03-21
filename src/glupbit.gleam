//// Glupbit — Type-safe Gleam client for the Upbit cryptocurrency exchange API.
////
//// ## Quick Start
////
//// ```gleam
//// import glupbit
//// import glupbit/quotation/market
////
//// // Public client (no auth needed)
//// let client = glupbit.new()
//// let assert Ok(pairs) = market.list_all(client)
////
//// // Authenticated client from environment variables
//// let assert Ok(auth_client) = glupbit.new_from_env()
//// ```

import glupbit/auth
import glupbit/client
import glupbit/types

/// Create a public client for quotation (market data) endpoints.
pub fn new() -> client.PublicClient {
  client.new_public()
}

/// Create an authenticated client for all endpoints.
pub fn new_auth(creds: auth.Credentials) -> client.AuthClient {
  client.new_auth(credentials: creds)
}

/// Create an authenticated client from environment variables.
pub fn new_from_env() -> Result(client.AuthClient, String) {
  client.new_auth_from_env()
}

/// Wrap a raw string as an AccessKey.
pub fn access_key(key: String) -> auth.AccessKey {
  auth.access_key(key)
}

/// Wrap a raw string as a SecretKey.
pub fn secret_key(key: String) -> auth.SecretKey {
  auth.secret_key(key)
}

/// Bundle credentials from an access key and secret key.
pub fn credentials(ak: auth.AccessKey, sk: auth.SecretKey) -> auth.Credentials {
  auth.credentials(ak, sk)
}

/// Parse a market code like `"KRW-BTC"` into a validated Market.
pub fn market(code: String) -> Result(types.Market, Nil) {
  types.market(code)
}

/// Downcast an AuthClient to a PublicClient for quotation calls.
pub fn to_public(auth_client: client.AuthClient) -> client.PublicClient {
  client.to_public(auth_client)
}
