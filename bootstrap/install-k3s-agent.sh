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
: "${K3S_SERVER_URL:?Set K3S_SERVER_URL in .env}"
: "${K3S_TOKEN:?Set K3S_TOKEN in .env}"

export INSTALL_K3S_VERSION="$K3S_VERSION"
export K3S_URL="$K3S_SERVER_URL"
export K3S_TOKEN="$K3S_TOKEN"
export INSTALL_K3S_EXEC="agent --node-name=${K3S_NODE_NAME}"

echo "Installing k3s agent version $K3S_VERSION..."
echo "Connecting to server: $K3S_SERVER_URL"

if ! curl -sfL https://get.k3s.io | sh -; then
  echo "Error: k3s agent installation failed" >&2
  exit 1
fi

if ! systemctl is-active --quiet k3s-agent; then
  echo "Error: k3s-agent service failed to start" >&2
  exit 1
fi

echo "K3s agent installed successfully"
echo "Node: $K3S_NODE_NAME"
