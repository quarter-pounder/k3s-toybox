# Observability Stack

Prometheus, Grafana, Loki, and Alloy. Metrics from Prometheus, logs from Loki (collected by Alloy). All components run in the `observability` namespace.

## Prerequisites

- Helm 3 (installed by `make prep` on Fedora)
- Cluster running with `observability` namespace (apply `cluster/namespaces.yaml` first)
- kubectl configured and able to reach the cluster

## Cluster access

Helm uses the same kubeconfig as kubectl. If `Kubernetes cluster unreachable: Get "http://localhost:8080/version"` is present, Helm is not using a kubeconfig.

On the k3s server node:

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl get nodes
```

If that works, run the helm commands below in the same shell (or add the export to the profile). Alternatively copy the kubeconfig: `mkdir -p ~/.kube && cp /etc/rancher/k3s/k3s.yaml ~/.kube/config`.

From another machine: copy `/etc/rancher/k3s/k3s.yaml` from the server, replace `127.0.0.1` in the server URL with the server IP, then set `KUBECONFIG` or place the file at `~/.kube/config`.

## Helm Repositories

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

## Install Order

Install in this order so dependencies resolve (Loki first, then Grafana with Loki datasource, then Alloy).

### 1. Loki

```bash
helm install loki grafana/loki \
  -n observability \
  -f apps/observability/loki-values.yaml \
  --create-namespace
```

Uses MinIO for object storage (dev/test). For production, configure S3 or another backend per [Loki Helm reference](https://grafana.com/docs/loki/latest/setup/install/helm/reference/).

### 2. kube-prometheus-stack (Prometheus + Grafana)

```bash
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n observability \
  -f apps/observability/kube-prometheus-stack-values.yaml
```

Grafana is configured with Prometheus (default) and Loki datasources. Default login: `admin` / `admin` (override in values).

### 3. Alloy (logs to Loki)

Config is in `apps/observability/alloy/config.alloy`. Pass it via `--set-file`:

```bash
helm install alloy grafana/alloy \
  -n observability \
  -f apps/observability/alloy-values.yaml \
  --set-file alloy.configMap.content=apps/observability/alloy/config.alloy
```

Alloy runs as a DaemonSet, mounts `/var/log` from the host, and ships pod logs to Loki.

## Access Grafana

Port-forward:

```bash
kubectl port-forward -n observability svc/kube-prometheus-stack-grafana 3000:80
```

Open http://localhost:3000. Log in with the credentials set in `kube-prometheus-stack-values.yaml` (default `admin` / `admin`).

- **Explore > Prometheus**: metrics
- **Explore > Loki**: logs (select Loki datasource, use LogQL)

## Upgrade

```bash
helm upgrade loki grafana/loki -n observability -f apps/observability/loki-values.yaml
helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack -n observability -f apps/observability/kube-prometheus-stack-values.yaml
helm upgrade alloy grafana/alloy -n observability -f apps/observability/alloy-values.yaml --set-file alloy.configMap.content=apps/observability/alloy/config.alloy
```

## Uninstall

Reverse order (Alloy, then kube-prometheus-stack, then Loki):

```bash
helm uninstall alloy -n observability
helm uninstall kube-prometheus-stack -n observability
helm uninstall loki -n observability
```

## Files

| File | Purpose |
|------|---------|
| `loki-values.yaml` | Loki monolithic, persistence |
| `kube-prometheus-stack-values.yaml` | Prometheus, Grafana, Alertmanager, node-exporter, kube-state-metrics; Loki datasource |
| `alloy-values.yaml` | Alloy DaemonSet, varlog mount, NODE_NAME env |
| `alloy/config.alloy` | Alloy River config: Kubernetes pod logs to Loki |

## Alloy Config

`alloy/config.alloy` defines:

- `loki.write "default"`: push to `http://loki:3100/loki/api/v1/push`
- `discovery.kubernetes "pod"`: discover pods on the same node (DaemonSet)
- `discovery.relabel "pod_logs"`: labels for namespace, pod, container, job, `__path__`
- `loki.source.kubernetes "pod_logs"`: tail pod logs from host paths
- `loki.process "pod_logs"`: add `cluster` label, forward to Loki

To change the cluster label or Loki URL, edit `alloy/config.alloy` and run `helm upgrade` with the same `--set-file` as install.
