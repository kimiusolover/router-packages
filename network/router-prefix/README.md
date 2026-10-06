# router-prefix

`router-prefix` is the target-side lower layer for `routerctl prefix`. It
creates an RFC 4193 ULA `/48` once, persists it at
`/var/lib/routeros/prefix/ula`, and derives deterministic `/64` allocations.

Selection is strict: `StaticPrefix` in `/etc/routeros/prefix.conf`, then a
validated DHCPv6-PD record at `/run/routeros/prefix/delegated`, then the
persistent ULA. A received WAN RA `/64` is deliberately never used as a LAN
source. The PD client writes `[Prefix]` and `Prefix=<delegated /48 or /56>`
only after lease validation, preferably via `write-delegated` (atomic rename).

The manager writes active state and allocations below `/run/routeros/prefix`.
`active` includes `NATRequired=yes|no` so independent consumers (e.g.
`router-ipv6-nat`) can decide NAT66 without owning prefix selection.

`router-network` owns Linux topology and atomically publishes the runtime mapping:

```text
/run/routeros/network/prefix-map
lan=br-lan
guest=guest
iot=iot
```

`prefix-manager` remains logical: `lan=1`, `guest=2`, `iot=3`, `vpn=4`.
`prefix-apply` resolves mapped allocations to Linux interface names and writes
`20-routeros-<linux-interface>.network.d/` fragments. `vpn` remains in the
allocation registry but is skipped until router-network publishes a mapping;
missing mappings for required topology interfaces are fatal. There is no
fallback from a logical name to an interface name. Kea and Jool must consume this same registry; the generator does
not own their configuration.

## PD lifecycle

```
delegated create / modify / delete
        ↓
router-prefix-delegated.path
        ↓
router-prefix-refresh.service
        ├── prefix-manager ensure
        ├── prefix-apply apply
        └── router-ipv6-nat-refresh.service (if installed)
```

| State | Source | NATRequired |
|-------|--------|-------------|
| No PD | generated | yes |
| PD present | delegated | no |
| PD lost | generated | yes |
| Static GUA | static | no |
| Static ULA | static | yes |

This is an internal component: a package build requires a clean
`router-packages` checkout and records its exact commit in
`/usr/share/routeros/provenance/router-prefix-build.json`. External source
archives remain subject to the `router-upstream` source-lock contract.

## Topology contract

`router-network` creates the VLAN/bridge topology and does not delegate it to
`prefix-manager` or `hostapd`. The default topology is:

```text
enp2s0 -- VLAN10 -- lan -- br-lan -- wlan0
enp2s0 -- VLAN20 -- guest
enp2s0 -- VLAN30 -- iot
```

The LAN IPv4 address `192.168.10.1/24` belongs to `br-lan`; the `lan` VLAN
subinterface has no L3 address.
