# AKS Migration Foundations

An introductory workshop for [Replatforming a Real-Time Messaging System to AKS](https://chadhage.github.io/aks-irl/index.html).

It takes the same **Skybridge** estate — a Java socket gateway, a C/C++ parser, and PostgreSQL —
and covers this sequence: **classic → containers → Kubernetes → AKS**. Starting from a
classic VM deployment, hand-managed configuration, and manual release, it ends with the workload
running on a managed AKS cluster. The AKS replatform workshop then covers production configuration.

## Delivery modes

The workshop offers the same activities and assessments in two modes:

- **Self-paced** — independent completion in approximately 12–14 hours (the hands-on activities plus the required reading, knowledge checks, and reflection). Trainer talk tracks and demo cues are hidden.
- **Instructor-led** — cohort delivery in approximately 7 hours of guided hands-on activity. The lab displays phase-level trainer talk tracks and demo cues.

Choose a mode on the landing page or open `lab.html?mode=self` or `lab.html?mode=led` directly. The selection and participant progress are saved in the browser, and the mode can be changed from the lab guide.

## Reading before the workshop

Complete the required reading before starting. It orients you to the cloud-native patterns and Azure end-state concepts (such as landing zones) that frame this journey — some are configured only in the follow-on replatform workshop:

- [Cloud Design Patterns — Azure Architecture Center](https://learn.microsoft.com/en-us/azure/architecture/patterns/)
- [What is an Azure landing zone?](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)
- [Azure Samples: Cloud Design Patterns](https://github.com/Azure-Samples/cloud-design-patterns)

Recommended reading:

- [On .NET Live: Clean Architecture, Vertical Slices, and Modular Monoliths (Oh My!)](https://learn.microsoft.com/en-us/shows/on-dotnet/on-dotnet-live-clean-architecture-vertical-slices-and-modular-monoliths-oh-my)
- [ASP.NET Core: Feature Slices for ASP.NET Core MVC](https://learn.microsoft.com/en-us/archive/msdn-magazine/2016/september/asp-net-core-feature-slices-for-asp-net-core-mvc)

## Contents

| File | Purpose |
| --- | --- |
| [`index.html`](index.html) | Landing page — scenario, the before/after journey, phase overview, and the hand-off boundary. |
| [`lab.html`](lab.html) | Participant activity guide — eight phases, each activity with a pre-check, steps, validation, and post-check, plus browser-saved progress tracking. |
| [`styles.css`](styles.css) | Shared theme (dark default, light toggle). No external dependencies. |

## The eight phases

0. **Setup & the legacy baseline** — toolchain, sample, and documentation of how it ships today.
1. **Deploy it using the existing process** — systemd + runbook on a "VM", followed by a configuration-drift and rollback exercise.
2. **Configuration management** — externalize settings to the environment (12-factor); get secrets out of source and images.
3. **Containerize the components** — multi-stage Dockerfiles for the JVM gateway, C/C++ parser, and static console; harden and scan.
4. **Compose the system & publish images** — run the estate locally with Compose; tag by semver + SHA; push to a registry.
5. **A container-based development lifecycle** — CI build/test/scan/push per commit; define the run contract each image needs.
6. **Kubernetes: orchestrate the containers** — local cluster; Deployments and Services; ConfigMaps and Secrets; self-heal, scale, roll out and roll back.
7. **Deploy to AKS (managed Kubernetes)** — provision AKS; push images to ACR; deploy the same manifests; expose with a LoadBalancer.

## Scope boundary

This workshop gets the workload **running on AKS**; it does not configure the cluster for production.
Production configuration — Day-0 cluster architecture, a private API server,
availability zones, workload identity, service mesh, GitOps rings, cluster/pod autoscaling, and DR —
is covered by the AKS replatform workshop that follows.

## Running it

It's a static site — open `index.html` in a browser, or serve the folder:

```bash
python -m http.server 8000   # then open http://localhost:8000
```

---

Instructor-led training content. Sample material, not configured for production. MIT-style use.
