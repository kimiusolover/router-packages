# router-ipv6-nat

Independent consumer of the `router-prefix` registry. Applies nftables NAT66
when `NATRequired=yes` in `/run/routeros/prefix/active`; flushes otherwise.

Does not select or allocate prefixes. Does not configure networkd RA.

## Units

| Unit | Role |
|------|------|
| `router-ipv6-nat.service` | boot apply (`Requires=prefix-manager.service`) |
| `router-ipv6-nat-refresh.service` | runtime re-apply after PD refresh |

## Rule

```
table ip6 routeros_nat6 {
    chain postrouting {
        type nat hook postrouting priority srcnat;
        ip6 saddr <active Prefix> oifname "<WAN>" counter masquerade
    }
}
```

Uses masquerade (not fixed SNAT) so WAN GUA changes from RA are followed.
Owns table `routeros_nat6` only; coordinate with firewall4 if reloads drop it.
