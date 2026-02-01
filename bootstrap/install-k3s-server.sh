#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (or via sudo)." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/.env" ]]; then
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/.env"
fi

: "${K3S_VERSION:?Set K3S_VERSION in .env}"
: "${K3S_NODE_NAME:?Set K3S_NODE_NAME in .env}"

DISABLE_ARGS=""
if [[ -n "${K3S_DISABLE:-}" ]]; then
  DISABLE_ARGS="--disable=${K3S_DISABLE}"
fi

FLANNEL_ARGS=""
if [[ -n "${K3S_FLANNEL_BACKEND:-}" ]]; then
  FLANNEL_ARGS="--flannel-backend=${K3S_FLANNEL_BACKEND}"
fi

export INSTALL_K3S_VERSION="$K3S_VERSION"
export INSTALL_K3S_EXEC="server \
  --node-name=${K3S_NODE_NAME} \
  ${DISABLE_ARGS} \
  ${FLANNEL_ARGS} \
  --write-kubeconfig-mode=${K3S_WRITE_KUBECONFIG_MODE:-0644}"

echo "Installing k3s server version $K3S_VERSION..."

if ! curl -sfL https://get.k3s.io | sh -; then
  echo "Error: k3s installation failed" >&2
  exit 1
fi

if ! systemctl is-active --quiet k3s; then
  echo "Error: k3s service failed to start" >&2
  exit 1
fi

echo "K3s server installed successfully"
echo "Node: $K3S_NODE_NAME"
echo "Try: kubectl get nodes"
