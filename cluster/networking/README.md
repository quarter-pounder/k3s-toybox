# Networking

ingress-nginx controller and Ingress resources. Use when Traefik is disabled on k3s.

## Prerequisites

- Cluster running
- Helm 3, KUBECONFIG set
- Ports 80 and 443 open in firewalld (included in `make firewall`)

## Install ingress-nginx

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx \
  --create-namespace \
  -f cluster/networking/ingress-nginx-values.yaml
```

Wait until the controller is ready and the LoadBalancer has an external IP (on k3s this is the node IP):

```bash
kubectl get svc -n ingress-nginx
```

## Grafana Ingress

Expose Grafana via hostname so you can use `http://grafana.toybox.local` instead of port-forward.

1. Apply the Ingress:

```bash
kubectl apply -f cluster/networking/grafana-ingress.yaml
```

2. Resolve the hostname to the node IP. On the machine where you open the browser, add to `/etc/hosts` (replace with your node IP):

```
192.168.0.231 grafana.toybox.local
```

3. Open http://grafana.toybox.local in the browser.

## Echo app Ingress

After deploying the playground echo app (`make deploy-playground` or `kubectl apply -f apps/playground/test-services/echo-app.yaml`), apply the echo Ingress:

```bash
kubectl apply -f apps/playground/test-services/echo-ingress.yaml
```

Add to `/etc/hosts`: `<node-ip> app.toybox.local`. Open http://app.toybox.local to hit the echo app (returns request metadata including hostname; useful for chaos experiments).

## Adding more Ingresses

Create an Ingress with `ingressClassName: nginx`, a host (e.g. `app.toybox.local`), and a backend service. Add the host to `/etc/hosts` pointing at the node IP.

## Uninstall

```bash
kubectl delete -f cluster/networking/grafana-ingress.yaml
helm uninstall ingress-nginx -n ingress-nginx
```
