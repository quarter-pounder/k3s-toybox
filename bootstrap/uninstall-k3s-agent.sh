#!/usr/bin/env bash
set -euo pipefail
if [[ $EUID -ne 0 ]]; then
  echo "Run as root (or via sudo)." >&2
  exit 1
fi
exec /usr/local/bin/k3s-agent-uninstall.sh
