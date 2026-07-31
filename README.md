# AKS Zero-to-Hero

A hands-on **prequel** to [Replatforming a Real-Time Messaging System to AKS](https://chadhage.github.io/aks-irl/index.html).

It takes the same **Skybridge** estate — a Java socket gateway, a C/C++ parser, and PostgreSQL —
and walks a participant the whole way: **classic → containers → Kubernetes → AKS**. Starting from a
classic VM deployment, hand-managed configuration, and manual release, it ends with the workload
running **live on a managed AKS cluster**. The AKS replatform workshop then takes that naive
deployment and hardens it for production.

## Contents

| File | Purpose |
| --- | --- |
| [`index.html`](index.html) | Landing page — scenario, the before/after journey, phase overview, and the hand-off boundary. |
| [`lab.html`](lab.html) | Participant activity guide — eight phases, each activity with a pre-check, steps, validation, and post-check, plus browser-saved progress tracking. |
| [`styles.css`](styles.css) | Shared theme (dark default, light toggle). No external dependencies. |

## The eight phases

0. **Setup & the legacy baseline** — toolchain, sample, honest documentation of how it ships today.
1. **Deploy it the classic way** — systemd + runbook on a "VM", then feel config drift and a painful rollback.
2. **Configuration management** — externalize settings to the environment (12-factor); get secrets out of source and images.
3. **Containerize the components** — multi-stage Dockerfiles for the JVM gateway, C/C++ parser, and static console; harden and scan.
4. **Compose the system & publish images** — run the estate locally with Compose; tag by semver + SHA; push to a registry.
5. **A container-based development lifecycle** — CI build/test/scan/push per commit; define the run contract each image needs.
6. **Kubernetes: orchestrate the containers** — local cluster; Deployments and Services; ConfigMaps and Secrets; self-heal, scale, roll out and roll back.
7. **Land on AKS (managed Kubernetes)** — provision AKS; push images to ACR; deploy the same manifests; expose with a LoadBalancer; bring the workload up live.

## The boundary (on purpose)

Zero-to-Hero gets the workload **running on AKS**; it does not make that cluster production-grade.
Everything that hardens a live AKS deployment — Day-0 cluster architecture, a private API server,
availability zones, workload identity, service mesh, GitOps rings, cluster/pod autoscaling, and DR —
is **owned by the AKS replatform workshop** that follows.

## Running it

It's a static site — open `index.html` in a browser, or serve the folder:

```bash
python -m http.server 8000   # then open http://localhost:8000
```

---

Instructor-led training content. Sample material, not production-hardened. MIT-style use.
