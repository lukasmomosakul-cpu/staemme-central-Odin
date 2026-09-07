# Egress provider evaluation

## Decision

For the first gateway, use Oracle Cloud Always Free as the development candidate, but keep the gateway provider-agnostic.

Oracle documents that its Always Free resources are available for an unlimited period. The 30-day US$300 credit is a separate trial. An Always Free E2.1.Micro includes one public IP and up to 50 Mbps internet bandwidth. Oracle may reclaim idle Always Free compute instances when CPU/network utilization remains below its stated thresholds for seven days.

## Important limitation

This does **not** mean unlimited free public IPv4 addresses. A single Always Free VM should be treated as one egress identity. Additional fixed IPv4 identities may require additional resources or a paid provider.

## Architecture

Device -> secure tunnel -> Odin gateway -> account-specific egress identity -> game

The web application never receives or stores VPN private keys. Gateway credentials remain server-side.

## Provider abstraction

The database/application should store provider, region, public IPv4, endpoint, status and capabilities rather than assuming Oracle. This allows later migration to Hetzner or another VPS without changing account/network-profile semantics.

## No open proxy

Do not expose a generic unauthenticated HTTP/SOCKS proxy. Use an authenticated tunnel such as WireGuard and restrict forwarding to explicitly assigned team/account routes.

## Next implementation step

Provision one development gateway and verify:
1. fixed public IPv4 is visible from the gateway;
2. secure tunnel can be established from a test device;
3. traffic exits through the gateway IPv4;
4. gateway health can be reported to Odin;
5. no private gateway credentials reach the browser.
