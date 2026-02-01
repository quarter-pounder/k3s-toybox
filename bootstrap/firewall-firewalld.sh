#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (or via sudo)." >&2
  exit 1
fi

echo "Configuring firewalld for k3s..."

if ! systemctl is-active --quiet firewalld; then
  echo "Error: firewalld is not running" >&2
  exit 1
fi

firewall-cmd --permanent --add-port=6443/tcp || {
  echo "Error: Failed to add port 6443/tcp" >&2
  exit 1
}

firewall-cmd --permanent --add-port=8472/udp || {
  echo "Error: Failed to add port 8472/udp" >&2
  exit 1
}

firewall-cmd --permanent --add-port=10250/tcp || {
  echo "Error: Failed to add port 10250/tcp" >&2
  exit 1
}

firewall-cmd --reload || {
  echo "Error: Failed to reload firewalld" >&2
  exit 1
}

echo "Firewalld rules applied successfully"
