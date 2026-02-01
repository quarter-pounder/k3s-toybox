# k3s-toybox

A k3s learning lab for experimenting with Kubernetes, chaos engineering, and cluster operations on Fedora.

## Prerequisites

- Fedora (tested on Fedora Server)
- Root access
- Network connectivity

## Repository Structure

```
k3s-toybox/
├── bootstrap/          # Node prep and k3s installation scripts
├── cluster/            # Cluster-level configs (namespaces, storage, networking)
├── apps/               # Application deployments (observability, CI, playground)
├── workloads/          # Stateless and stateful workload examples
├── chaos/              # Chaos engineering experiments
├── backups/            # Backup snapshots and restore tests
├── docs/               # Architecture notes and experiment logs
├── Makefile            # Task runner for common operations
└── README.md
```

## Quick Start

### 1. Clone and configure

```bash
git clone <repo-url> && cd k3s-toybox
cp bootstrap/env.example bootstrap/.env
```

Edit `bootstrap/.env`:

```bash
K3S_VERSION="v1.31.5+k3s1"
K3S_NODE_NAME="toybox-0"
K3S_DISABLE="traefik"
K3S_WRITE_KUBECONFIG_MODE="0644"
K3S_FLANNEL_BACKEND="vxlan"
```

### 2. Bootstrap server node

```bash
sudo make prep        # Install packages, disable swap, configure kernel
sudo make firewall    # Open ports 6443, 8472, 10250
sudo make server      # Install k3s server
```

### 3. Verify

```bash
make status           # kubectl get nodes
```

### 4. (Optional) Add agent nodes

On the server, get the join token:

```bash
sudo make token
```

On the agent node, configure `bootstrap/.env`:

```bash
K3S_VERSION="v1.31.5+k3s1"
K3S_NODE_NAME="toybox-1"
K3S_SERVER_URL="https://<server-ip>:6443"
K3S_TOKEN="<token-from-server>"
```

Then run:

```bash
sudo make prep
sudo make firewall
sudo make agent
```

## Makefile Targets

| Target | Description |
|--------|-------------|
| `make prep` | Node preparation (packages, swap, sysctl, firewalld) |
| `make firewall` | Open k3s ports in firewalld |
| `make server` | Install k3s server |
| `make agent` | Install k3s agent |
| `make status` | Show node status |
| `make token` | Print join token (server only) |
| `make teardown-server` | Uninstall k3s server |
| `make teardown-agent` | Uninstall k3s agent |
| `make env-check` | Validate bootstrap/.env |

## Firewall Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 6443 | TCP | Kubernetes API |
| 8472 | UDP | Flannel VXLAN |
| 10250 | TCP | Kubelet metrics |

## Teardown

```bash
sudo make teardown-server  # or teardown-agent
```

This runs the official k3s uninstall script which removes all k3s data and configurations.

## Notes

- Traefik is disabled by default; install ingress-nginx or re-enable Traefik as needed
- Kubeconfig is at `/etc/rancher/k3s/k3s.yaml` with mode 0644
- Node token is at `/var/lib/rancher/k3s/server/node-token`
