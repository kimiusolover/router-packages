# router-dslite

DS-Lite (Dual-Stack Lite): **IPv4 Internet over the existing IPv6 WAN**.

Independent of DHCPv6-PD. MEC may return `NoPrefixAvail` for IA_PD while WAN
GUA from RA still works; DS-Lite only needs that WAN IPv6 path plus an AFTR.

Does not allocate LAN prefixes. Does not configure NAT66 (see `router-ipv6-nat`).

## Layering

```text
router-nic-discovery
  → router-network          (WAN IPv6 RA, VLAN)
  → router-prefix           (ULA / PD registry)
  → router-ipv6-nat         (ULA → WAN GUA when needed)
  → router-dslite           (this package: IPv4 over IPv6)
  → nftables / firewall
```

| Path | Mechanism |
|------|-----------|
| LAN IPv6 | ULA + NAT66 or delegated prefix |
| LAN IPv4 | DS-Lite tunnel → AFTR → IPv4 Internet |

## Units

| Unit | Role |
|------|------|
| `router-dslite.service` | boot apply |
| `router-dslite-refresh.service` | re-apply after WAN IPv6 change |

## Configuration

`/etc/routeros/router-dslite.conf` (defaults under `/usr/lib/routeros/`):

```ini
[DSLite]
Enabled=yes
WAN=enp2s0
AFTR=                    # optional; auto discovery is future work
Backend=auto             # auto | stub | ip6tnl | jool
TunnelInterface=ds-lite
IPv4DefaultRoute=yes
MTU=
```

`AFTR` is optional because BB.excite光 MEC does not require manual AFTR input. When it is empty, the skeleton records that automatic discovery is pending; `apply` waits for a resolved AFTR rather than hard-coding a provider endpoint.

## AFTR discovery

The DHCPv6 client is responsible for requesting RFC 6334 `OPTION_AFTR_NAME`
(option 64). A client hook writes the returned FQDN to
`/run/routeros/dslite/aftr-name`; `router-dslite-discover` validates the name,
resolves one global AAAA record over IPv6, verifies the route through `WAN`,
and atomically writes `/run/routeros/dslite/aftr`.

The discovery adapter does not parse DHCPv6 packets itself. This keeps the
DHCPv6 client integration replaceable and prevents provider-specific AFTR
addresses from being hard-coded. `router-dslite-discover.path` reruns the
adapter when the hook changes `aftr-name`; a successful discovery then runs
the current skeleton apply path.

```text
DHCPv6 client option 64 hook
  → /run/routeros/dslite/aftr-name
  → router-dslite-discover.service
  → /run/routeros/dslite/aftr
  → router-dslite apply (stub or ip6tnl; route is added only after tunnel setup)
```

Discovery state is written to `/run/routeros/dslite/discovery-status`. An
invalid FQDN, missing AAAA, or unreachable endpoint removes the previous
resolved AFTR and fails closed.

## Backends

| Backend | Status |
|---------|--------|
| `auto` | **Default.** Selects the available skeleton backend; currently equivalent to `stub`. |
| `stub` | Checks WAN GUA + an explicitly supplied AFTR; writes `/run/routeros/dslite/state`. No tunnel. |
| `ip6tnl` | Creates the kernel IPv4-in-IPv6 B4 tunnel, assigns `B4Address`, and adds a metric-scoped IPv4 default route after successful tunnel setup. |
| `jool` | Planned: use the `jool` package after ISP DS-Lite mode is confirmed. |

## Runtime state

| Path | Content |
|------|---------|
| `/run/routeros/dslite/status` | Ready=yes/no and last message |
| `/run/routeros/dslite/state` | Active parameters after successful apply |
| `/run/routeros/dslite/aftr-name` | DHCPv6 hook input: AFTR FQDN |
| `/run/routeros/dslite/aftr` | Resolved global AFTR IPv6 address |
| `/run/routeros/dslite/discovery-status` | AFTR discovery result |

## Commands

```sh
router-dslite check    # prerequisites only
router-dslite apply    # apply (stub: state file only)
router-dslite status
router-dslite stop
```

## MTU / MSS

DS-Lite encapsulates IPv4 in IPv6; effective MTU is lower than native IPv4.
Set `MTU=` after path tests. `IPv4RouteMetric=` defaults to 50 and the route
stage uses `ip route add`, never unconditional `ip route replace`; an existing
native default remains present. Coordinate MSS clamping with nftables (not
owned by this package).
