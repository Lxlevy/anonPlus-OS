#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root (for example: sudo ./scripts/network-up.sh)." >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOR_NS="anonplus-tor"
APP_NS="anonplus-app"
HOST_VETH="ap-host"
TOR_HOST_VETH="ap-tor-host"
TOR_APP_VETH="ap-tor-app"
APP_VETH="ap-app-veth"
WAN_IF="$(ip -4 route show default | awk 'NR == 1 {print $5}')"
TOR_UID="$(id -u debian-tor 2>/dev/null || true)"

for command in ip nft sysctl tor; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command. Run make setup first." >&2
    exit 1
  fi
done

[[ -n "$WAN_IF" ]] || { echo "Could not determine the host WAN interface." >&2; exit 1; }
[[ -n "$TOR_UID" ]] || { echo "The debian-tor user is missing." >&2; exit 1; }

"$ROOT_DIR/scripts/network-down.sh" || true

mkdir -p /etc/netns/anonplus-app
cat > /etc/netns/anonplus-app/resolv.conf <<'EOF'
nameserver 10.200.1.1
options timeout:2 attempts:2
EOF

ip netns add "$TOR_NS"
ip netns add "$APP_NS"

ip link add "$HOST_VETH" type veth peer name "$TOR_HOST_VETH"
ip link set "$TOR_HOST_VETH" netns "$TOR_NS"
ip addr add 10.200.0.1/30 dev "$HOST_VETH"
ip link set "$HOST_VETH" up
ip -n "$TOR_NS" link set "$TOR_HOST_VETH" name tor-host
ip -n "$TOR_NS" addr add 10.200.0.2/30 dev tor-host
ip -n "$TOR_NS" link set tor-host up
ip -n "$TOR_NS" link set lo up
ip -n "$TOR_NS" route add default via 10.200.0.1

ip link add "$TOR_APP_VETH" type veth peer name "$APP_VETH"
ip link set "$TOR_APP_VETH" netns "$TOR_NS"
ip link set "$APP_VETH" netns "$APP_NS"
ip -n "$TOR_NS" link set "$TOR_APP_VETH" name tor-app
ip -n "$TOR_NS" addr add 10.200.1.1/30 dev tor-app
ip -n "$TOR_NS" link set tor-app up
ip -n "$APP_NS" addr add 10.200.1.2/30 dev "$APP_VETH"
ip -n "$APP_NS" link set "$APP_VETH" up
ip -n "$APP_NS" link set lo up
ip -n "$APP_NS" route add default via 10.200.1.1

sysctl -q -w net.ipv4.ip_forward=1

nft -f - <<EOF
table inet anonplus_host {
  chain forward {
    type filter hook forward priority 0; policy drop;
    iifname "$HOST_VETH" oifname "$WAN_IF" accept
    iifname "$WAN_IF" oifname "$HOST_VETH" ct state established,related accept
  }
}
table ip anonplus_nat {
  chain postrouting {
    type nat hook postrouting priority srcnat; policy accept;
    oifname "$WAN_IF" ip saddr 10.200.0.0/30 masquerade
  }
}
EOF

ip netns exec "$TOR_NS" nft -f - <<EOF
table inet anonplus_router {
  chain prerouting {
    type nat hook prerouting priority dstnat; policy accept;
    iifname "tor-app" ip protocol tcp tcp dport != 9040 redirect to :9040
    iifname "tor-app" ip protocol udp udp dport 53 redirect to :5353
  }
  chain forward {
    type filter hook forward priority 0; policy drop;
    iifname "tor-app" oifname "tor-host" ip protocol tcp accept
    iifname "tor-app" oifname "tor-host" ip protocol udp udp dport 53 accept
    iifname "tor-host" oifname "tor-app" ct state established,related accept
  }
  chain output {
    type filter hook output priority 0; policy drop;
    oifname "lo" accept
    meta skuid $TOR_UID oifname "tor-host" tcp dport 1-65535 accept
    meta skuid $TOR_UID oifname "tor-host" udp dport 53 accept
    ct state established,related accept
  }
  chain input {
    type filter hook input priority 0; policy drop;
    iifname "lo" accept
    iifname "tor-app" tcp dport 9040 accept
    iifname "tor-app" udp dport 5353 accept
    ct state established,related accept
  }
}
EOF

mkdir -p /var/lib/anonplus-tor
chown -R debian-tor:debian-tor /var/lib/anonplus-tor
ip netns exec "$TOR_NS" tor -f "$ROOT_DIR/config/tor/torrc" > /var/log/anonplus-tor.log 2>&1 &
echo $! > /run/anonplus-tor.pid

if ! timeout "${ANONPLUS_TOR_BOOTSTRAP_TIMEOUT:-120}" bash -c \
  'until grep -q "Bootstrapped 100%" /var/log/anonplus-tor.log; do sleep 1; done'; then
  echo "Tor did not bootstrap; application networking remains unavailable." >&2
  "$ROOT_DIR/scripts/network-down.sh"
  exit 1
fi

echo "anonPlus network is up"
echo "  Tor namespace: $TOR_NS"
echo "  App namespace: $APP_NS"
echo "  Tor log: /var/log/anonplus-tor.log"
