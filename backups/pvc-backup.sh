#!/bin/bash
# PVC backup script using kubectl exec and tar
# Backs up PVC data from a pod that mounts the PVC

set -euo pipefail

NAMESPACE="${NAMESPACE:-}"
PVC_NAME="${PVC_NAME:-}"
POD_NAME="${POD_NAME:-}"
BACKUP_DIR="${BACKUP_DIR:-/root/k3s-backups/pvc}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

if [ -z "${NAMESPACE}" ] || [ -z "${PVC_NAME}" ]; then
    echo "Usage: NAMESPACE=<ns> PVC_NAME=<pvc> [POD_NAME=<pod>] ./pvc-backup.sh" >&2
    echo "Example: NAMESPACE=apps PVC_NAME=postgresql-pvc POD_NAME=postgresql-0 ./pvc-backup.sh" >&2
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "kubectl not found" >&2
    exit 1
fi

if [ -z "${POD_NAME}" ]; then
    echo "Finding pod with PVC ${PVC_NAME} in namespace ${NAMESPACE}..."
    POD_NAME=$(kubectl get pods -n "${NAMESPACE}" -o jsonpath='{.items[?(@.spec.volumes[*].persistentVolumeClaim.claimName=="'"${PVC_NAME}"'")].metadata.name}' | awk '{print $1}')
    
    if [ -z "${POD_NAME}" ]; then
        echo "No pod found mounting PVC ${PVC_NAME}" >&2
        exit 1
    fi
    echo "Found pod: ${POD_NAME}"
fi

PVC_MOUNT_PATH=$(kubectl get pod "${POD_NAME}" -n "${NAMESPACE}" -o jsonpath='{.spec.containers[0].volumeMounts[?(@.name=="data")].mountPath}' || echo "/data")

if [ -z "${PVC_MOUNT_PATH}" ]; then
    PVC_MOUNT_PATH="/data"
    echo "Using default mount path: ${PVC_MOUNT_PATH}"
else
    echo "Using mount path: ${PVC_MOUNT_PATH}"
fi

mkdir -p "${BACKUP_DIR}"
BACKUP_FILE="${BACKUP_DIR}/${PVC_NAME}-${NAMESPACE}-${TIMESTAMP}.tar.gz"

echo "Backing up PVC ${PVC_NAME} from pod ${POD_NAME}..."
kubectl exec -n "${NAMESPACE}" "${POD_NAME}" -- tar czf - -C "${PVC_MOUNT_PATH}" . > "${BACKUP_FILE}"

if [ -f "${BACKUP_FILE}" ] && [ -s "${BACKUP_FILE}" ]; then
    BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
    echo "Backup complete: ${BACKUP_FILE} (${BACKUP_SIZE})"
    
    # Keep last 7 days of backups
    find "${BACKUP_DIR}" -name "${PVC_NAME}-${NAMESPACE}-*.tar.gz" -mtime +7 -delete 2>/dev/null || true
else
    echo "Backup failed or empty" >&2
    exit 1
fi
