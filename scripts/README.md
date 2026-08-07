# Workshop scripts

These scripts implement every `./scripts/*.sh` command used by `lab.html`. Run
them from the root of the complete Skybridge starter repository with a
Bash-compatible shell.

Start with:

```bash
./scripts/verify-prerequisites.sh
```

The supported minimums are Git 2.40, Docker Engine 24, Docker Compose 2.20,
Docker Scout 1.0, Azure CLI 2.60, kubectl 1.30, and kind 0.23.

The prerequisite gate validates both local tools and required starter assets.
This website repository contains the workshop guide and scripts, but not the
Skybridge application source, environment profiles, Kubernetes manifests, or CI
workflow. Asset-dependent scripts therefore fail with an actionable message
until those materials are added at the paths documented by the lab.

## Safety behavior

- Discovery and validation scripts are read-only.
- `run-release.sh` records local PIDs and replaces only processes it previously
  started.
- Failure injection requires the expected `kind-z2h` or `aks-z2h` kubectl
  context, permits only one active injection per scope, and is reversed by the
  matching reset script.
- `inject-aks-failure.sh assigned` requires the instructor to set
  `AKS_FAILURE_MODE` explicitly.
- `set-aks-images.sh` resolves already-pushed ACR tags to digests and renders
  local manifests. It never builds, pushes, or applies an image.
- Load evidence is written to `workshop-notes/load-runs/PROFILE.json`.

Run the script contract tests with:

```bash
./scripts/tests/run.sh
```
