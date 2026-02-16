# Understanding Kubernetes and k3s via This Repo

Reference for core Kubernetes and k3s concepts, with pointers to resources in this repository.

---

# Why?

I perfer learning via building. This is my personal toybox.

---

## Kubernetes and k3s

**Kubernetes** is a container orchestrator: it schedules workloads, keeps them healthy, and provides networking and storage abstractions.

**k3s** is a minimal, single-binary Kubernetes distribution (Rancher). It is API-compatible with Kubernetes and ships fewer components. This repo bootstraps k3s via `bootstrap/install-k3s-server.sh` and `install-k3s-agent.sh`; standard Kubernetes manifests and `kubectl` apply unchanged.

---

## Core Concepts

### Cluster and Nodes

A **cluster** is a set of nodes managed by a control plane. The **control plane** (API server, etcd, scheduler, controller managers) runs as a single process on the k3s server. **Nodes** run workloads; k3s distinguishes server nodes (control plane + workloads) and agent nodes (workloads only, joined via token). See `docs/architecture.md` for topology.

### Namespaces

Namespaces partition resources and provide scope for names and policies. `cluster/namespaces.yaml` defines `observability`, `apps`, `playground`, and `ci`. Workloads and Ingress resources reference these namespaces.

### Pods

A **pod** is the smallest schedulable unit: one or more containers sharing network and storage. Pods are typically created and managed by controllers, not directly. Example: the echo app in `apps/playground/test-services/echo-app.yaml` runs one container per pod; `chaos/kill-pod.sh` deletes a pod and the Deployment controller replaces it to satisfy `replicas: 2`.

### Workload Controllers

| Controller   | Role                                      | In this repo                                      |
|-------------|-------------------------------------------|---------------------------------------------------|
| Deployment  | Stateless, declarative replicas and updates| `echo-app.yaml`, `workloads/stateless/*.yaml`     |
| StatefulSet | Stable identity and storage per replica    | `workloads/stateful/postgresql.yaml`              |
| DaemonSet   | One pod per node                          | Alloy in `apps/observability/alloy-values.yaml`   |

### Services

A **Service** exposes a stable network endpoint and load-balances to pods matching its selector. **ClusterIP** (default) is internal only. **LoadBalancer** on k3s typically gets the node IP. Example: echo Service in `echo-app.yaml` selects pods with `app: echo`; Grafana Ingress in `cluster/networking/grafana-ingress.yaml` uses service `kube-prometheus-stack-grafana`. CoreDNS resolves names such as `echo.playground.svc.cluster.local`.

### Ingress

**Ingress** defines HTTP(S) routing by host and path. An Ingress controller (here: ingress-nginx in `cluster/networking/`) implements it. Traefik is disabled in k3s; `cluster/networking/README.md` and `ingress-nginx-values.yaml` document the setup. `grafana-ingress.yaml` and `apps/playground/test-services/echo-ingress.yaml` route external traffic to Services.

### Volumes and Persistent Storage

**PersistentVolumeClaim (PVC)** requests storage; a **StorageClass** defines how it is provisioned. k3s uses `local-path-provisioner` (hostPath). `cluster/storage/storageclass.yaml` declares the default class. `workloads/stateful/postgresql.yaml` uses `volumeClaimTemplates` so each StatefulSet replica gets durable storage; data survives pod restarts.

### ConfigMaps and Secrets

**ConfigMaps** hold non-secret configuration; **Secrets** hold sensitive data. Alloy’s River config is supplied via a ConfigMap (`apps/observability/alloy-values.yaml`, `--set-file alloy.configMap.content=...`).

---

## Control Plane and Data Flow

Control plane: API server (REST API), etcd (cluster state), scheduler (pod placement), controller manager (reconciliation). k3s bundles these in one binary. Cluster state is backed up via `backups/etcd-snapshot.sh`.

Request path for the echo app: client → Ingress (host) → ingress-nginx → echo Service → echo pods. The Service load-balances across healthy pods.

---

## k3s in This Repo

- Single binary; optional components (e.g. Traefik) can be disabled via `bootstrap/.env`.
- Built-in: CoreDNS, Flannel (VXLAN), local-path-provisioner, Metrics Server (see `docs/architecture.md`).
- Kubeconfig: `/etc/rancher/k3s/k3s.yaml`.
- Network: Pod CIDR 10.42.0.0/16, Service CIDR 10.43.0.0/16.

---

## Resource-to-File Reference

| Concept       | Example location(s)                                              |
|---------------|------------------------------------------------------------------|
| Namespace     | `cluster/namespaces.yaml`                                        |
| Deployment    | `apps/playground/test-services/echo-app.yaml`, `workloads/stateless/` |
| StatefulSet   | `workloads/stateful/postgresql.yaml`                             |
| DaemonSet     | Alloy: `apps/observability/alloy-values.yaml`                    |
| Service       | `echo-app.yaml`, `workloads/stateful/postgresql.yaml`            |
| Ingress       | `cluster/networking/grafana-ingress.yaml`, `echo-ingress.yaml`   |
| PVC / Storage | `cluster/storage/`, `workloads/stateful/postgresql.yaml`         |
