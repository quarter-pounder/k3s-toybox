# Experiments Log

## Template

### Experiment: [Name]
**Date**: YYYY-MM-DD
**Goal**: What are we testing?
**Setup**: Steps to reproduce
**Result**: What happened?
**Learnings**: Key takeaways

---

## Experiments

### Experiment: Kill pod in playground
**Date**: (fill when run)
**Goal**: Observe pod kill and recovery; see which pod serves the next request.
**Setup**:
1. Deploy echo app: `make deploy-playground` or `kubectl apply -f apps/playground/test-services/echo-app.yaml`
2. Hit the app a few times (curl or browser via app.toybox.local). Note hostname in response.
3. Run chaos: `./chaos/kill-pod.sh playground`
4. Hit the app again immediately, then a few more times over 30s.
**Result**: (fill: did you see a different hostname? How long until the killed pod was back?)
**Learnings**: (fill: scheduler latency, service routing, logs in Loki?)

---

## Planned Experiments

- [ ] Pod resource limits and OOM behavior
- [ ] Node drain and pod rescheduling
- [ ] Network policy enforcement
- [ ] Persistent volume failover
- [ ] CPU/memory stress testing
- [ ] Rolling update strategies
- [ ] Backup and restore procedures
 - [ ] Disk fill chaos
 - [ ] Network partition chaos