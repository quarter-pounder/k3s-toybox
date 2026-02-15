# Playground

Test services for chaos experiments and learning. Deploy here to stress, kill, or break things and observe in Grafana/Prometheus/Loki.

## Echo app

Lightweight HTTP app that returns request metadata (including hostname). When killing a pod, the next request may hit another pod and show a different hostname.

### Deploy

```bash
kubectl apply -f apps/playground/test-services/echo-app.yaml
kubectl apply -f apps/playground/test-services/echo-ingress.yaml
```

Or from repo root: `make deploy-playground`.

### Access

- **Cluster-internal**: `kubectl run curl --rm -it --image=curlimages/curl -- curl -s http://echo.playground.svc.cluster.local`
- **Via ingress**: Add to `/etc/hosts`: `<node-ip> app.toybox.local`, then open http://app.toybox.local (requires ingress-nginx and `cluster/networking/` setup).

### Chaos

Kill a random pod in playground and watch recovery:

```bash
./chaos/kill-pod.sh playground
```

Then curl again; there might be a different hostname (another pod) or a brief gap until the killed pod is recreated.

See `docs/experiments.md` for a sample experiment log.

## Other chaos targets

- **CPU stress**: `kubectl apply -f chaos/cpu-stress.yaml` (runs in playground, 60s)
- **Memory stress**: `kubectl apply -f chaos/memory-stress.yaml`
- **Network delay**: `kubectl apply -f chaos/network-delay.yaml`

Remove when done: `kubectl delete -f chaos/<file>.yaml`.
