#!/usr/bin/env bash
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
for t in test-single-nic.sh test-multi-nic.sh test-unassigned.sh \
         test-dup-vlan-id.sh test-dup-vlan-name.sh; do
  bash "$here/$t"
done
echo 'all router-network tests passed'
