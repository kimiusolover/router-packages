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
AFTR=                    # optional; DHCPv6 option 64 discovery
Backend=auto             # auto | stub | ip6tnl | jool
TunnelInterface=ds-lite
IPv4DefaultRoute=yes
MTU=
IPv4Forwarding=yes
LANInterfaces=lan,guest,iot
Firewall=allow
```

`AFTR` is optional because BB.excite光 MEC does not require manual AFTR input. When it is empty, the discovery orchestrator tries DHCPv6 Option 64 and then transix DNS; `apply` waits for a resolved AFTR rather than hard-coding a provider endpoint.

## AFTR discovery

The discovery orchestrator uses this priority:

```text
1. Explicit AFTR=
2. DHCPv6 RFC 6334 OPTION_AFTR_NAME=64
3. transix DNS AAAA for gw.transix.jp
4. Last-known-good AFTR while its TTL is valid
5. Stop DS-Lite if no valid AFTR remains
```

The implementation is split into adapters:

| Program | Responsibility |
|---------|----------------|
| `router-dslite-discover` | Priority, validation, atomic state, TTL cache and fail-closed behavior |
| `router-dslite-discover-dhcp6` | Validate the DHCPv6 hook's AFTR FQDN and resolve its AAAA record |
| `router-dslite-discover-transix` | Query all `gw.transix.jp` AAAA records, preserve DNS order, capture TTL, and select the first WAN-routed candidate |

The transix adapter does not hard-code `gw.transix.jp` addresses and does not use
the unverified `4over6.info TXT → setup46` mechanism. The adapter first obtains DNS servers associated with the WAN using `resolvectl dns <WAN>`, then queries each server explicitly with `dig -6 @<DNS>`. It tries the next configured DNS server when a query fails. A DNS answer is only a candidate until it is a global
IPv6 address with a route through the configured WAN. The later DS-Lite tunnel
apply remains the final end-to-end validation.

The discovery service only discovers and writes state. The DS-Lite service performs the single `apply`; the path-triggered refresh service performs discovery followed by apply.

The selected AFTR and metadata are written atomically to:

```text
/run/routeros/dslite/aftr
/run/routeros/dslite/aftr-meta
/run/routeros/dslite/discovery-status
```

A transient discovery failure does not tear down an active tunnel when the
last-known-good entry is still within its TTL. Once the cache expires, the
orchestrator removes the AFTR state and stops the DS-Lite lifecycle.

RFC 6334 requires a conforming DHCPv6 client to include option 64 in its
Option Request Option. If a Reply still has no AFTR-Name after that request is
confirmed on the wire, the transix DNS adapter is the fallback.

## Backends

| Backend | Status |
|---------|--------|
| `auto` | **Default.** Resolves to the production `ip6tnl` backend when an AFTR is available. |
| `stub` | Diagnostic-only backend. Checks WAN GUA + AFTR and writes state; no tunnel. |
| `ip6tnl` | Creates the kernel IPv4-in-IPv6 B4 tunnel, assigns `B4Address`, and adds a metric-scoped IPv4 default route after successful tunnel setup. |
| `jool` | Planned: use the `jool` package after ISP DS-Lite mode is confirmed. |

## LAN IPv4 forwarding and firewall

For `Backend=ip6tnl`, a successful tunnel and route setup then enables
`net.ipv4.ip_forward=1`. The previous sysctl value is recorded in state and
restored by `router-dslite stop`; a failed later step rolls it back.

The default LAN set is logical: `lan,guest,iot`. At apply time these names are resolved through `/run/routeros/network/prefix-map`, so the firewall uses `br-lan,guest,iot` after bridge topology is active. The package owns
only the `inet routeros_dslite` nftables table. Its stateful rules allow:

```text
lan, guest, iot → ds-lite   new,established,related
ds-lite → lan, guest, iot   established,related
```

The table deliberately uses `policy accept` so it does not become a second
global default-deny firewall or block IPv6 control traffic to the AFTR. The
existing system firewall remains responsible for the global forwarding policy.
Set `Firewall=disabled`/`no` when that firewall owns the DS-Lite allow rule.
The package does **not** add IPv4 masquerade: DS-Lite IPv4 NAT belongs to the
AFTR, while `router-ipv6-nat` independently handles IPv6 NAT66.

The implementation records `IPv4Forwarding=configured`, `Firewall=configured`,
and both logical `LANInterfaces=...` and resolved `LANLinuxInterfaces=...` in `/run/routeros/dslite/state`. It does not claim
IPv4 Internet connectivity until the router itself and each LAN VLAN are
validated against a real AFTR.

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
router-dslite apply    # apply tunnel, route, forwarding and firewall when enabled
router-dslite status
router-dslite stop
```

## MTU / MSS

DS-Lite encapsulates IPv4 in IPv6; effective MTU is lower than native IPv4.
Set `MTU=` after path tests. `IPv4RouteMetric=` defaults to 50 and the route
stage uses `ip route add`, never unconditional `ip route replace`; an existing
native default remains present. Coordinate MSS clamping with nftables (not
owned by this package).
