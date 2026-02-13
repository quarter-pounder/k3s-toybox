#!/bin/bash
# Test restore from etcd snapshot
# WARNING: This will restore the cluster to a previous state
# Run on k3s server node as root

set -euo pipefail

SNAPSHOT_FILE="${1:-}"
SNAPSHOT_DIR="${SNAPSHOT_DIR:-/root/k3s-backups}"

if [ "$EUID" -ne 0 ]; then
    echo "Run as root or with sudo" >&2
    exit 1
fi

if [ -z "${SNAPSHOT_FILE}" ]; then
    echo "Usage: $0 <snapshot-file>" >&2
    echo "Available snapshots:" >&2
    ls -lh "${SNAPSHOT_DIR}"/etcd-snapshot-*.db 2>/dev/null || echo "  (none found)" >&2
    exit 1
fi

if [ ! -f "${SNAPSHOT_FILE}" ]; then
    echo "Snapshot file not found: ${SNAPSHOT_FILE}" >&2
    exit 1
fi

if ! command -v k3s &> /dev/null; then
    echo "k3s not found. Run on k3s server node." >&2
    exit 1
fi

echo "WARNING: This will restore the cluster from snapshot ${SNAPSHOT_FILE}"
echo "All current cluster state will be replaced."
read -p "Continue? (yes/no): " CONFIRM

if [ "${CONFIRM}" != "yes" ]; then
    echo "Restore cancelled"
    exit 0
fi

echo "Stopping k3s..."
systemctl stop k3s || true

BACKUP_DIR="/var/lib/rancher/k3s/server/db"
RESTORE_DIR="${BACKUP_DIR}.restore"

if [ -d "${RESTORE_DIR}" ]; then
    echo "Removing existing restore directory..."
    rm -rf "${RESTORE_DIR}"
fi

echo "Restoring from snapshot..."
k3s server \
    --cluster-reset \
    --cluster-reset-restore-path="${SNAPSHOT_FILE}" \
    --data-dir="${BACKUP_DIR}"

echo "Restore complete. Starting k3s..."
systemctl start k3s

echo "Waiting for k3s to get ready..."
sleep 10

if systemctl is-active --quiet k3s; then
    echo "k3s is running. Verify cluster: kubectl get nodes"
else
    echo "k3s failed to start. Check logs: journalctl -u k3s" >&2
    exit 1
fi
