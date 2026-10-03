#!/usr/bin/env bash
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
pkg=$(cd "$here/../../network/router-network" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

ROUTER_NETWORK_DISCOVERY=$here/fixtures/single-nic.conf \
ROUTER_NETWORK_CONFIG=$here/fixtures/network.conf \
ROUTER_NETWORK_RUN=$work/network \
ROUTER_NETWORK_STATE=$work/state \
ROUTER_NETWORK_RELOAD=no \
  "$pkg/files/router-network" apply

expect=(
  10-routeros-wan.network
  20-routeros-lan.netdev
  20-routeros-lan.network
  20-routeros-guest.netdev
  20-routeros-guest.network
  20-routeros-iot.netdev
  20-routeros-iot.network
)
for f in "${expect[@]}"; do
  [[ -f $work/network/$f ]] || { echo "missing: $f" >&2; exit 1; }
done

grep -qx 'Name=enp2s0' "$work/network/10-routeros-wan.network"
for v in lan guest iot; do
  grep -qx "VLAN=$v" "$work/network/10-routeros-wan.network"
done
grep -qx 'Id=10' "$work/network/20-routeros-lan.netdev"
grep -qx 'Address=192.168.10.1/24' "$work/network/20-routeros-lan.network"
grep -qx 'Address=192.168.20.1/24' "$work/network/20-routeros-guest.network"
grep -qx 'Address=192.168.30.1/24' "$work/network/20-routeros-iot.network"
grep -qx 'Parent=enp2s0' "$work/state/lan"

echo 'test-single-nic: ok'
