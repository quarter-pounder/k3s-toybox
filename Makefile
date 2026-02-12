# k3s-toybox bootstrap and cluster operations
# Run targets that execute scripts with sudo (prep, firewall, server, agent, teardown-*) as root or via: make target ARGS="sudo"
# Run make from repo root so script paths resolve correctly.

ROOT_DIR := $(CURDIR)
BOOTSTRAP_DIR := $(ROOT_DIR)/bootstrap
SHELL := /bin/bash

.PHONY: help prep firewall server agent status token teardown-server teardown-agent env-check deploy-playground pods logs events apply-namespaces install-ingress install-observability install-all

help:
	@echo "Bootstrap (run as root or: make <target> ARGS=sudo):"
	@echo "  make prep             - Node prep (packages, swap, sysctl, firewalld enable)"
	@echo "  make firewall         - Open k3s ports in firewalld"
	@echo "  make server           - Install k3s server (requires .env in bootstrap/)"
	@echo "  make agent            - Install k3s agent (requires .env with K3S_SERVER_URL, K3S_TOKEN)"
	@echo ""
	@echo "Operations:"
	@echo "  make status           - Cluster node status (kubectl get nodes)"
	@echo "  make token            - Print join token (run on server node as root)"
	@echo "  make teardown-server  - Uninstall k3s server"
	@echo "  make teardown-agent   - Uninstall k3s agent"
	@echo ""
	@echo "Playground:"
	@echo "  make deploy-playground - Deploy echo app and ingress in playground"
	@echo "  make pods             - Pods (all namespaces)"
	@echo "  make logs             - Tail logs (usage: make logs POD=name NS=namespace)"
	@echo "  make events           - Recent cluster events"
	@echo ""
	@echo "Setup:"
	@echo "  make env-check        - Verify bootstrap/.env exists and required vars set"
	@echo "  make apply-namespaces - Apply cluster namespaces"
	@echo "  make install-ingress  - Install ingress-nginx controller"
	@echo "  make install-observability - Install Loki, Prometheus/Grafana, Alloy"
	@echo "  make install-all      - Apply namespaces, install ingress and observability"

prep:
	$(or $(ARGS),sudo) bash $(BOOTSTRAP_DIR)/node-prep-fedora.sh

firewall:
	$(or $(ARGS),sudo) bash $(BOOTSTRAP_DIR)/firewall-firewalld.sh

server: env-check
	$(or $(ARGS),sudo) bash $(BOOTSTRAP_DIR)/install-k3s-server.sh

agent: env-check
	$(or $(ARGS),sudo) bash $(BOOTSTRAP_DIR)/install-k3s-agent.sh

status:
	kubectl get nodes -o wide 2>/dev/null || (echo "kubectl not available or no kubeconfig" >&2; exit 1)

token:
	@if [ -f /var/lib/rancher/k3s/server/node-token ]; then \
		$(or $(ARGS),sudo) cat /var/lib/rancher/k3s/server/node-token; \
	else \
		echo "Not a k3s server or node-token missing" >&2; exit 1; \
	fi

teardown-server:
	$(or $(ARGS),sudo) bash $(BOOTSTRAP_DIR)/uninstall-k3s-server.sh

teardown-agent:
	$(or $(ARGS),sudo) bash $(BOOTSTRAP_DIR)/uninstall-k3s-agent.sh

deploy-playground:
	kubectl apply -f $(ROOT_DIR)/apps/playground/test-services/echo-app.yaml
	kubectl apply -f $(ROOT_DIR)/apps/playground/test-services/echo-ingress.yaml
	@echo "Echo app deployed. Add to /etc/hosts: <node-ip> app.toybox.local"

pods:
	kubectl get pods -A -o wide

logs:
	@if [ -z "$(POD)" ]; then echo "Usage: make logs POD=<pod-name> [NS=<namespace>]" >&2; exit 1; fi; \
	kubectl logs -n $(or $(NS),default) -f $(POD) --tail=50

events:
	kubectl get events -A --sort-by='.lastTimestamp' | tail -30

env-check:
	@test -f $(BOOTSTRAP_DIR)/.env || (echo "Create $(BOOTSTRAP_DIR)/.env from $(BOOTSTRAP_DIR)/env.example" >&2; exit 1)
	@. "$(BOOTSTRAP_DIR)/.env" 2>/dev/null; test -n "$$K3S_VERSION" || (echo "K3S_VERSION not set in .env" >&2; exit 1)
	@. "$(BOOTSTRAP_DIR)/.env" 2>/dev/null; test -n "$$K3S_NODE_NAME" || (echo "K3S_NODE_NAME not set in .env" >&2; exit 1)

apply-namespaces:
	kubectl apply -f $(ROOT_DIR)/cluster/namespaces.yaml

install-ingress: apply-namespaces
	@echo "Adding ingress-nginx Helm repo..."
	@helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>/dev/null || true
	@helm repo update ingress-nginx
	@echo "Installing ingress-nginx..."
	@helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
		-n ingress-nginx \
		--create-namespace \
		-f $(ROOT_DIR)/cluster/networking/ingress-nginx-values.yaml \
		--wait --timeout 5m || (echo "Installation failed or timed out. Check: kubectl get pods -n ingress-nginx" >&2; exit 1)
	@echo "ingress-nginx installed. Get external IP: kubectl get svc -n ingress-nginx"

install-observability: apply-namespaces
	@echo "Adding Helm repos..."
	@helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
	@helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
	@helm repo update grafana prometheus-community
	@echo "Installing Loki..."
	@helm upgrade --install loki grafana/loki \
		-n observability \
		-f $(ROOT_DIR)/apps/observability/loki-values.yaml \
		--create-namespace \
		--wait --timeout 5m || (echo "Loki installation failed" >&2; exit 1)
	@echo "Installing kube-prometheus-stack..."
	@helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
		-n observability \
		-f $(ROOT_DIR)/apps/observability/kube-prometheus-stack-values.yaml \
		--wait --timeout 10m || (echo "Prometheus/Grafana installation failed" >&2; exit 1)
	@echo "Installing Alloy..."
	@helm upgrade --install alloy grafana/alloy \
		-n observability \
		-f $(ROOT_DIR)/apps/observability/alloy-values.yaml \
		--set-file alloy.configMap.content=$(ROOT_DIR)/apps/observability/alloy/config.alloy \
		--wait --timeout 5m || (echo "Alloy installation failed" >&2; exit 1)
	@echo "Observability stack installed. Port-forward Grafana: kubectl port-forward -n observability svc/kube-prometheus-stack-grafana 3000:80"

install-all: apply-namespaces install-ingress install-observability
	@echo "All components installed. Next steps:"
	@echo "  1. Apply Grafana ingress: kubectl apply -f cluster/networking/grafana-ingress.yaml"
	@echo "  2. Add to /etc/hosts: <node-ip> grafana.toybox.local"
	@echo "  3. Access Grafana at http://grafana.toybox.local (default: admin/admin)"
