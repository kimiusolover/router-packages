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

`prefix-apply` turns allocations into `/run/systemd/network/*.network.d/`
fragments. Kea and Jool must consume this same registry; the generator does
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
