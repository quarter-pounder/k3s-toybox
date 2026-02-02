# k3s-toybox bootstrap and cluster operations
# Run targets that execute scripts with sudo (prep, firewall, server, agent, teardown-*) as root or via: make target ARGS="sudo"
# Run make from repo root so script paths resolve correctly.

ROOT_DIR := $(CURDIR)
BOOTSTRAP_DIR := $(ROOT_DIR)/bootstrap
SHELL := /bin/bash

.PHONY: help prep firewall server agent status token teardown-server teardown-agent env-check

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
	@echo "Setup:"
	@echo "  make env-check        - Verify bootstrap/.env exists and required vars set"

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

env-check:
	@test -f $(BOOTSTRAP_DIR)/.env || (echo "Create $(BOOTSTRAP_DIR)/.env from $(BOOTSTRAP_DIR)/env.example" >&2; exit 1)
	@. "$(BOOTSTRAP_DIR)/.env" 2>/dev/null; test -n "$$K3S_VERSION" || (echo "K3S_VERSION not set in .env" >&2; exit 1)
	@. "$(BOOTSTRAP_DIR)/.env" 2>/dev/null; test -n "$$K3S_NODE_NAME" || (echo "K3S_NODE_NAME not set in .env" >&2; exit 1)
