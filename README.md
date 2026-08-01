# Containerization and AKS Workshop

An introductory workshop for [Replatforming a Real-Time Messaging System to AKS](https://chadhage.github.io/aks-irl/index.html).

It starts with the code-complete **Skybridge** estate — a Java socket gateway, a C/C++ parser,
an operations console, and PostgreSQL — ready to be tested and promoted. Participants already know
the classic model: copy an artifact into dev, test, UAT, and production environments whose installed
runtimes and configuration help determine how that artifact behaves. The workshop uses that shared
experience as a contrast, then covers **container → registry → Kubernetes → AKS → operations**.

The workshop uses one immutable image across registration and promotion stages. Participants
derive a container contract, package and operate the application locally, publish traceable images,
express the runtime contract as Kubernetes workloads, deploy those workloads to AKS, and use logs,
events, metrics, and controlled load to diagnose and improve runtime behavior.

## Delivery modes

The workshop offers the same activities and assessments in two modes:

- **Self-paced** — independent completion in approximately 14–16 hours (hands-on activities, required reading, knowledge checks, and operational reflection). Trainer talk tracks and demo cues are hidden.
- **Instructor-led** — cohort delivery in approximately 9 hours of guided hands-on activity. The lab displays phase-level trainer talk tracks and demo cues.

Choose a mode on the landing page or open `lab.html?mode=self` or `lab.html?mode=led` directly. The selection and participant progress are saved in the browser, and the mode can be changed from the lab guide.

## Reading before the workshop

Complete the required reading before starting. It covers cloud-native patterns and Azure concepts such as landing zones; some are configured only in the follow-on replatform workshop:

- [Cloud Design Patterns — Azure Architecture Center](https://learn.microsoft.com/en-us/azure/architecture/patterns/)
- [What is an Azure landing zone?](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)
- [Azure Samples: Cloud Design Patterns](https://github.com/Azure-Samples/cloud-design-patterns)

Recommended reading:

- [On .NET Live: Clean Architecture, Vertical Slices, and Modular Monoliths (Oh My!)](https://learn.microsoft.com/en-us/shows/on-dotnet/on-dotnet-live-clean-architecture-vertical-slices-and-modular-monoliths-oh-my)
- [ASP.NET Core: Feature Slices for ASP.NET Core MVC](https://learn.microsoft.com/en-us/archive/msdn-magazine/2016/september/asp-net-core-feature-slices-for-asp-net-core-mvc)

## Contents

| File | Purpose |
| --- | --- |
| [`index.html`](index.html) | Overview — scenario, delivery-model comparison, phase list, and scope boundary. |
| [`lab.html`](lab.html) | Participant activity guide — nine phases, each activity with a pre-check, steps, validation, and post-check, plus browser-saved progress tracking. |
| [`styles.css`](styles.css) | Shared theme (dark default, light toggle). No external dependencies. |

## The nine phases

0. **Orient from the model you know** — verify the code-complete release and contrast environment-based promotion with immutable-image promotion.
1. **Derive the container contract** — translate the existing runtime assumptions into explicit image, configuration, health, security, and resource requirements.
2. **Separate image from environment** — externalize settings and secrets so one image can move through dev, test, UAT, and production.
3. **Build and operate the containers** — create minimal, non-root Java, C/C++, and console images; inspect logs, processes, networks, and resource behavior.
4. **Run the system with Compose** — run the estate locally and validate service discovery, health, persistence, and end-to-end behavior.
5. **Register and automate** — test, scan, label, tag, publish, and pull immutable images through CI; record their run contracts.
6. **Kubernetes: Pods, Deployments, and Services** — move the same containers to a local cluster with configuration, probes, resources, reconciliation, rollout, and rollback.
7. **Deploy the workload to AKS** — provision AKS, integrate ACR, deploy the same workload definitions, and expose the gateway.
8. **Observe, diagnose, and optimize on AKS** — establish a load baseline, investigate failures with logs/events/metrics, tune the workload, and compare the measurements.

## Scope boundary

This workshop deploys the workload to AKS and covers basic workload diagnostics and resource tuning; it does not configure the cluster for production.
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
