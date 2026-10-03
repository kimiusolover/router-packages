#!/usr/bin/env bash
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
pkg=$(cd "$here/../../network/router-network" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# WAN が unassigned のままでは、勝手に WAN を選ばず失敗しなければならない
if ROUTER_NETWORK_DISCOVERY=$here/fixtures/multi-nic.conf \
   ROUTER_NETWORK_CONFIG=$here/fixtures/network.conf \
   ROUTER_NETWORK_RUN=$work/network \
   ROUTER_NETWORK_STATE=$work/state \
   ROUTER_NETWORK_RELOAD=no \
     "$pkg/files/router-network" apply 2>"$work/stderr"; then
  echo 'test-multi-nic: expected failure but succeeded' >&2
  exit 1
fi

grep -q 'WAN is unassigned' "$work/stderr"
[[ ! -e $work/network/10-routeros-wan.network ]] || {
  echo 'test-multi-nic: WAN network file must not be generated' >&2
  exit 1
}

echo 'test-multi-nic: ok'
