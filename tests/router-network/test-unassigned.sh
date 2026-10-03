#!/usr/bin/env bash
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
pkg=$(cd "$here/../../network/router-network" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# discovery 結果ファイル自体が無い場合も exit != 0
if ROUTER_NETWORK_DISCOVERY=$work/does-not-exist.conf \
   ROUTER_NETWORK_CONFIG=$here/fixtures/network.conf \
   ROUTER_NETWORK_RUN=$work/network \
   ROUTER_NETWORK_STATE=$work/state \
   ROUTER_NETWORK_RELOAD=no \
     "$pkg/files/router-network" apply 2>"$work/stderr"; then
  echo 'test-unassigned: expected failure but succeeded' >&2
  exit 1
fi

grep -q 'NIC discovery result not found' "$work/stderr"
echo 'test-unassigned: ok'
