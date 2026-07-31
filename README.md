# AKS Zero-to-Hero

A hands-on **prequel** to [Replatforming a Real-Time Messaging System to AKS](https://chadhage.github.io/aks-irl/index.html).

It takes the same **Skybridge** estate — a Java socket gateway, a C/C++ parser, and PostgreSQL —
and walks a participant from a **classic VM deployment, hand-managed configuration, and manual
release** to a clean **container-based development lifecycle**. It stops deliberately right before
orchestration and target architecture — exactly where the AKS replatform workshop picks up.

## Contents

| File | Purpose |
| --- | --- |
| [`index.html`](index.html) | Landing page — scenario, the before/after journey, phase overview, and the hand-off boundary. |
| [`lab.html`](lab.html) | Participant activity guide — six phases, each activity with a pre-check, steps, validation, and post-check, plus browser-saved progress tracking. |
| [`styles.css`](styles.css) | Shared theme (dark default, light toggle). No external dependencies. |

## The six phases

0. **Setup & the legacy baseline** — toolchain, sample, honest documentation of how it ships today.
1. **Deploy it the classic way** — systemd + runbook on a "VM", then feel config drift and a painful rollback.
2. **Configuration management** — externalize settings to the environment (12-factor); get secrets out of source and images.
3. **Containerize the components** — multi-stage Dockerfiles for the JVM gateway, C/C++ parser, and static console; harden and scan.
4. **Compose the system & publish images** — run the estate locally with Compose; tag by semver + SHA; push to a registry.
5. **A container-based development lifecycle** — CI build/test/scan/push per commit; close the inner/outer loop; package the hand-off.

## The boundary (on purpose)

Everything that requires a cluster to exist — Kubernetes objects, cluster architecture, node pools,
Ingress/Gateway, service mesh, autoscaling, and DR — is **out of scope here** and belongs to the AKS
replatform workshop that follows.

## Running it

It's a static site — open `index.html` in a browser, or serve the folder:

```bash
python -m http.server 8000   # then open http://localhost:8000
```

---

Instructor-led training content. Sample material, not production-hardened. MIT-style use.
