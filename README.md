# router-packages

Package recipes and package-level configuration for router firmware builds.

## Boundary

This repository groups downstream recipes by OS concern. Upstream source
versions and patch policy belong to `router-upstream`; board-specific settings
belong to `router-platform`; image assembly belongs to `router-firmware`.

```
core/       # base OS components such as systemd
network/    # Kea, Unbound, hostapd, Jool, nftables, router-prefix, and related services
packaging/  # shared package build and publication conventions
```

Each recipe must declare its upstream source-map identifier and must not embed
unverified source archives or board-specific regulatory values.

## Locked builds

`make build-<component>` builds one component only from a source map in a
locked `router-upstream` checkout.  It never downloads source code.  Provide:

```sh
export ROUTER_UPSTREAM_DIR=/path/to/router-upstream
export ROUTER_SOURCE_CACHE=/path/to/verified-archives
export DESTDIR=/path/to/package-root
make build-systemd
```

A source record must validate against `router-upstream`'s
`schemas/source-lock-v1.schema.json`, have `status: locked`, an immutable
revision, reviewed retrieval provenance, an archive cache filename, and a
matching SHA-256. The `router-upstream` checkout itself must be clean; a
locally modified lock record is rejected. The build never downloads a source
archive or substitutes a mirror or moving upstream reference. `hostapd` additionally requires a
target `CROSS_COMPILE`; `jool` requires `KERNEL_HEADERS` from the same locked
kernel build.  This repository deliberately contains no radio interface,
channel, country, calibration, DHCP pool, or WAN/LAN policy: those are
platform- and deployment-specific inputs.

`make check` validates all recipe syntax and the service-ordering drop-ins
without downloading or compiling software.

## IPv6 prefix runtime

`router-prefix` is a target-side IPv6 prefix runtime. It persists one RFC 4193
ULA `/48`, selects `static > DHCPv6-PD > ULA`, allocates configured `/64`s,
and writes runtime-only networkd fragments. It deliberately does not reuse a
WAN RA `/64` for LAN networks. See
[`network/router-prefix/README.md`](network/router-prefix/README.md).

## Tiny Planner

The five router service packages (`systemd`, `kea`, `unbound`, `hostapd`, and
`jool`) have a reusable policy overlay under `tiny/`. It declares the minimal
feature set without copying upstream source or embedding board facts. The
single contract is [`tiny/schema.json`](tiny/schema.json); each feature is
classified as `required`, `conditional`, `excluded`, or `upstream-required`.

Generate one package profile by combining the package policy with separate
device and certification capability inputs:

```sh
packaging/tiny-plan --package hostapd \
  --device router-platform-device.json \
  --certification reviewed-certification.json \
  --policy reviewed-deployment-policy.json \
  --output generated/tiny
```

The required inputs are JSON objects containing a `capabilities` string array;
certification entries must be `certification.*`, and the optional policy input
uses `policy.*`. The
planner emits `generated/tiny/<package>/profile.json`; it selects conditional
features only when all required capabilities exist. It does not infer hardware
facts or RF permission—those remain the responsibility of the separate inputs
and their review path. `make test-tiny-plan` exercises fail-closed conditional
selection locally.

Pass a generated profile to its matching locked build with `TINY_PROFILE`. Its
declared arguments are the only tiny-layer values forwarded to the upstream
build system; a profile for another package is rejected.
