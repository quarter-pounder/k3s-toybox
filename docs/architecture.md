# Architecture

## Cluster Topology

Single-node k3s server on Fedora. Agent nodes can be added as needed.

## Components

### Disabled by Default
- Traefik (install ingress-nginx or re-enable as needed)

### Included with k3s
- CoreDNS
- Flannel (VXLAN backend)
- local-path-provisioner
- Metrics Server (if not disabled)

## Network

- Pod CIDR: 10.42.0.0/16 (k3s default)
- Service CIDR: 10.43.0.0/16 (k3s default)
- Flannel VXLAN on port 8472/UDP

## Storage

- Default: local-path-provisioner (hostPath)
- Future: Longhorn for distributed storage experiments
