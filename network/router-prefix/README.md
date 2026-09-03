# router-prefix

`router-prefix` is the target-side lower layer for `routerctl prefix`. It
creates an RFC 4193 ULA `/48` once, persists it at
`/var/lib/routeros/prefix/ula`, and derives deterministic `/64` allocations.

Selection is strict: `StaticPrefix` in `/etc/routeros/prefix.conf`, then a
validated DHCPv6-PD record at `/run/routeros/prefix/delegated`, then the
persistent ULA. A received WAN RA `/64` is deliberately never used as a LAN
source. The PD client writes `[Prefix]` and `Prefix=<delegated /48 or /56>`
only after lease validation.

The manager writes active state and allocations below `/run/routeros/prefix`.
`prefix-apply` turns them into `/run/systemd/network/*.network.d/` fragments.
Kea and Jool must consume this same registry; the generator does not own their
configuration.

This is an internal component: a package build requires a clean
`router-packages` checkout and records its exact commit in
`/usr/share/routeros/provenance/router-prefix-build.json`. External source
archives remain subject to the `router-upstream` source-lock contract.
