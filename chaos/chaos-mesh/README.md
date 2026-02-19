# Chaos Mesh

Chaos Mesh is a cloud-native chaos engineering platform for Kubernetes. It provides various chaos types: PodChaos, NetworkChaos, StressChaos, TimeChaos, and more.

## Installation

Install via Makefile:

```bash
make install-chaos-mesh
```

Or manually:

```bash
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm repo update
helm install chaos-mesh chaos-mesh/chaos-mesh \
  -n chaos-mesh \
  --create-namespace \
  -f chaos/chaos-mesh-values.yaml
```

## Configuration

Values file: `chaos/chaos-mesh-values.yaml`

- Runtime: containerd (k3s default)
- Socket path: `/run/k3s/containerd/containerd.sock`
- Dashboard: enabled (ClusterIP service)
- Leader election: disabled (single replica)

## Access Dashboard

Port-forward:

```bash
make chaos-dashboard
```

Open http://localhost:2333 in a browser.

Default login: `admin` / `admin123456` (change via Helm values).

## Verify Installation

```bash
kubectl get pods -n chaos-mesh
kubectl get svc -n chaos-mesh
```

Expected pods:
- `chaos-controller-manager-*`
- `chaos-daemon-*`
- `chaos-dashboard-*`
- `chaos-dns-server-*`

## Uninstall

```bash
make uninstall-chaos-mesh
```

## Example Experiments

All examples target the playground echo app (`app: echo`, namespace `playground`). Deploy it first: `make deploy-playground`.

| File | Type | Description |
|------|------|-------------|
| `pod-kill-echo.yaml` | PodChaos | Kill one echo pod (Deployment recreates it) |
| `pod-failure-echo.yaml` | PodChaos | Make one pod unavailable for 30s |
| `network-delay-echo.yaml` | NetworkChaos | 200ms latency for 60s |
| `network-loss-echo.yaml` | NetworkChaos | 20% packet loss for 60s |
| `stress-cpu-echo.yaml` | StressChaos | CPU stress for 60s |
| `stress-memory-echo.yaml` | StressChaos | 256MB memory stress for 60s |
| `time-offset-echo.yaml` | TimeChaos | Clock +5m for 30s |

Apply: `kubectl apply -f chaos/chaos-mesh/<file>.yaml`  
Remove: `kubectl delete -f chaos/chaos-mesh/<file>.yaml`

To target other workloads, change `selector.namespaces` and `selector.labelSelectors` in the YAML.

## Documentation

- [Chaos Mesh Docs](https://chaos-mesh.org/docs/)
- [Chaos Types](https://chaos-mesh.org/docs/next/user-guides/chaos-experiments/)
