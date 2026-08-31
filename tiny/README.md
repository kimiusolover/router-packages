# Tiny layer

`tiny/<package>/features.yaml` is a policy overlay, never a copy or fork of
upstream source. Its shared v1 contract is described in `schema.json`.

Every feature has exactly one classification: `required`, `conditional`,
`excluded`, or `upstream-required`. Conditional features are selected only
when every declared capability is present.

For systemd, `runtime.binaries` and `runtime.units` form the generated binary
and unit allowlists. They remain ordinary feature entries, so systemd uses the
same schema and planner as the other packages.

Capabilities stay outside this repository. The Tiny Planner reads a device
manifest JSON and a certification profile JSON, each containing a
`capabilities` string array, and emits a generated profile. Certification
capabilities must be namespaced as `certification.*`; an optional deployment
policy input is namespaced as `policy.*`. A policy such as `wifi.he` therefore
does not claim that a particular board has 802.11ax or that it is authorised
to transmit.
