#!/bin/bash
# k3s etcd snapshot backup script
# Run on k3s server node as root or with sudo

set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/var/lib/rancher/k3s/server/db}"
SNAPSHOT_DIR="${SNAPSHOT_DIR:-/root/k3s-backups}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
SNAPSHOT_FILE="etcd-snapshot-${TIMESTAMP}.db"

if [ "$EUID" -ne 0 ]; then
    echo "Run as root or with sudo" >&2
    exit 1
fi

if ! command -v k3s &> /dev/null; then
    echo "k3s not found. Run on k3s server node." >&2
    exit 1
fi

mkdir -p "${SNAPSHOT_DIR}"

echo "Creating etcd snapshot..."
k3s etcd-snapshot \
    --snapshot-compress \
    --data-dir="${BACKUP_DIR}"

LATEST_SNAPSHOT=$(ls -t "${BACKUP_DIR}"/snapshot-*.db 2>/dev/null | head -1)

if [ -z "${LATEST_SNAPSHOT}" ]; then
    echo "No snapshot found in ${BACKUP_DIR}" >&2
    exit 1
fi

cp "${LATEST_SNAPSHOT}" "${SNAPSHOT_DIR}/${SNAPSHOT_FILE}"
echo "Snapshot saved to: ${SNAPSHOT_DIR}/${SNAPSHOT_FILE}"

# Keep last 7 days of snapshots
find "${SNAPSHOT_DIR}" -name "etcd-snapshot-*.db" -mtime +7 -delete 2>/dev/null || true

echo "Backup complete. Snapshots in: ${SNAPSHOT_DIR}"
