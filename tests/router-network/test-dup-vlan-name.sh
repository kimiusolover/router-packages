#!/usr/bin/env bash
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
pkg=$(cd "$here/../../network/router-network" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

if ROUTER_NETWORK_DISCOVERY=$here/fixtures/single-nic.conf \
   ROUTER_NETWORK_CONFIG=$here/fixtures/dup-vlan-name.conf \
   ROUTER_NETWORK_RUN=$work/network \
   ROUTER_NETWORK_STATE=$work/state \
   ROUTER_NETWORK_RELOAD=no \
     "$pkg/files/router-network" apply 2>"$work/stderr"; then
  echo 'test-dup-vlan-name: expected failure but succeeded' >&2
  exit 1
fi

grep -q 'duplicate VLAN interface name: lan' "$work/stderr"
[[ ! -e $work/network/10-routeros-wan.network ]] || {
  echo 'test-dup-vlan-name: network files must not be generated' >&2
  exit 1
}

echo 'test-dup-vlan-name: ok'
