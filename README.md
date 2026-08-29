# router-packages

Package recipes and package-level configuration for router firmware builds.

## Boundary

This repository groups downstream recipes by OS concern. Upstream source
versions and patch policy belong to `router-upstream`; board-specific settings
belong to `router-platform`; image assembly belongs to `router-firmware`.

```
core/       # base OS components such as systemd
network/    # Kea, Unbound, hostapd, Jool, nftables, and related services
packaging/  # shared package build and publication conventions
```

Each recipe must declare its upstream source-map identifier and must not embed
unverified source archives or board-specific regulatory values.
