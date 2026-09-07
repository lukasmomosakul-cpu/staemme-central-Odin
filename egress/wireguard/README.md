# Odin Egress Gateway – WireGuard

This directory contains the first gateway setup for the provider-agnostic egress architecture.

## Goal

`device -> WireGuard -> Odin gateway -> internet`

The gateway provides a stable public IPv4 for development/testing. The browser app must never contain or store WireGuard private keys.

## Oracle Always Free

Oracle currently provides Always Free compute resources for the lifetime of an account in its home region. An E2.1.Micro includes one public IPv4 and up to 50 Mbps internet bandwidth. Oracle can reclaim compute instances that remain idle according to its published 7-day utilization thresholds.

For the first development gateway, use an Always Free Linux VM and a **reserved public IPv4** so the egress identity survives VM reboots/redeployments.

## Create the gateway

1. In Oracle Cloud, create an Always Free compute instance in your **home region**.
2. Recommended first test: `VM.Standard.E2.1.Micro` with Ubuntu.
3. Create/use a VCN with a public subnet and internet gateway.
4. Assign a public IPv4 to the primary VNIC.
5. Convert that public IPv4 to a **reserved public IP**. Do not commit the address to Git.
6. Allow SSH (TCP 22) only from your own management network if practical.
7. Allow WireGuard UDP 51820 from the internet.
8. Keep the VM's SSH private key off GitHub and out of the Odin web app.

## Server setup

On the VM:

```bash
sudo apt update
sudo apt install -y wireguard iptables
```

Enable forwarding:

```bash
sudo tee /etc/sysctl.d/99-odin-wireguard.conf >/dev/null <<'EOF'
net.ipv4.ip_forward=1
EOF
sudo sysctl --system
```

Generate keys directly on the gateway:

```bash
sudo umask 077
wg genkey | sudo tee /etc/wireguard/server_private.key | wg pubkey | sudo tee /etc/wireguard/server_public.key
```

Do **not** paste either private key into GitHub, Supabase, Vercel, or the browser app.

## Network model for the first test

Use a dedicated tunnel subnet such as `10.66.0.0/24`:

- gateway: `10.66.0.1`
- first test client: `10.66.0.2`

The gateway performs NAT from the WireGuard subnet to its public interface. Replace `<PUBLIC_INTERFACE>` with the actual interface from `ip route get 1.1.1.1`.

Example NAT rule:

```bash
sudo iptables -t nat -A POSTROUTING -s 10.66.0.0/24 -o <PUBLIC_INTERFACE> -j MASQUERADE
```

For persistence, install the distro's iptables persistence mechanism after the routing test succeeds. Keep firewall rules minimal and explicit.

## Oracle networking checklist

The VM is not reachable just because it has a public IP. The VCN route table needs an internet gateway/default route, and the subnet security rules must allow the intended traffic. For WireGuard, add inbound UDP 51820. Keep SSH restricted.

## First validation

Before integrating this with Odin:

1. Confirm the gateway's public IPv4.
2. Connect one test device with WireGuard.
3. Visit an IP-check service from the device.
4. Confirm the observed public IPv4 equals the gateway's reserved IPv4.
5. Disconnect WireGuard and confirm the normal device IP returns.
6. Reconnect and confirm the same gateway IPv4 is used again.

Only after this works should we implement per-account egress routing (`Account A -> IP A`, `Account B -> IP B`).

## Security rules

- Never store WireGuard private keys in the repository.
- Never expose an unauthenticated HTTP/SOCKS proxy.
- The Odin frontend should store only metadata such as provider, region, public IPv4, endpoint and health status.
- Per-account routing must be enforced at the gateway, not trusted to client-side UI state.
- Use the setup for stable connectivity and account isolation in accordance with the game's rules; do not use it to bypass anti-bot/anti-cheat controls.
