#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
	echo "Run this test as root (for example: sudo make test)." >&2
	exit 1
fi

APP_NS="anonplus-app"
TOR_NS="anonplus-tor"
TEST_URL="${ANONPLUS_TEST_URL:-https://check.torproject.org/api/ip}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOR_STOPPED=0

restore_network() {
	if [[ "$TOR_STOPPED" -eq 1 ]]; then
		"$ROOT_DIR/scripts/network-up.sh" >/dev/null 2>&1 || true
	fi
}
trap restore_network EXIT

fail() {
	echo "FAIL: $1" >&2
	exit 1
}

ip netns list | grep -q "^${APP_NS} " || fail "application namespace is missing"
ip netns list | grep -q "^${TOR_NS} " || fail "Tor namespace is missing"

APP_LINKS="$(ip -n "$APP_NS" -o link show | awk -F': ' '{print $2}' | cut -d'@' -f1)"
ip -n "$APP_NS" link show lo >/dev/null || fail "application loopback is missing"
ip -n "$APP_NS" link show ap-app-veth >/dev/null || \
	fail "application veth is missing"
DEFAULT_ROUTES="$(ip -n "$APP_NS" route | awk '$1 == "default" {print}')"
[[ "$DEFAULT_ROUTES" == default\ via\ 10.200.1.1\ dev\ ap-app-veth* ]] || \
	fail "application namespace has an unexpected default route"

FIREWALL_RULES="$(ip netns exec "$TOR_NS" nft list table inet anonplus_router)"
grep -q 'policy drop' <<<"$FIREWALL_RULES" || \
	fail "Tor namespace firewall is not default-deny"
grep -q 'redirect to :9040' <<<"$FIREWALL_RULES" || \
	fail "TCP traffic is not redirected to Tor"
grep -q 'redirect to :5353' <<<"$FIREWALL_RULES" || \
	fail "DNS traffic is not redirected to Tor"

ip netns exec "$APP_NS" curl --silent --show-error --fail --max-time 60 \
	"$TEST_URL" | grep -q '"IsTor":true' || \
	fail "application traffic did not produce a Tor identity"

ip netns exec "$APP_NS" getent hosts example.com >/dev/null || \
	fail "DNS resolution through the application namespace failed"

mapfile -t TOR_PIDS < <(ip netns pids "$TOR_NS")
[[ "${#TOR_PIDS[@]}" -gt 0 ]] || fail "Tor process is missing"
kill -TERM "${TOR_PIDS[0]}"
TOR_STOPPED=1
if timeout 20 ip netns exec "$APP_NS" curl --silent --show-error --fail --max-time 10 \
	"$TEST_URL" >/dev/null 2>&1; then
	fail "application traffic continued after Tor stopped"
fi

echo "PASS: namespaces, fail-closed firewall, Tor routing, DNS, and Tor-stop behavior"
