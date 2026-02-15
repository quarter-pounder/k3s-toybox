# Backup and Restore

Backup scripts for k3s cluster state (etcd) and PVC data.

## Prerequisites

- Run backup scripts on the k3s server node
- Root access for etcd snapshots
- kubectl configured for PVC backups

## etcd Snapshots

Backup the entire cluster state (all resources, configs, etc.).

### Create Snapshot

```bash
sudo ./backups/etcd-snapshot.sh
```

Snapshots are saved to `/root/k3s-backups/` by default. Set `SNAPSHOT_DIR` to change location:

```bash
sudo SNAPSHOT_DIR=/backup/k3s ./backups/etcd-snapshot.sh
```

Snapshots older than 7 days are automatically deleted.

### Restore from Snapshot

**WARNING**: This will replace the current cluster state with the snapshot state.

```bash
sudo ./backups/restore-test.sh /root/k3s-backups/etcd-snapshot-20240212-120000.db
```

The script will:
1. Stop k3s
2. Restore from the snapshot
3. Start k3s

Verify after restore: `kubectl get nodes`

## PVC Backups

Backup data from PersistentVolumeClaims. Requires a pod that mounts the PVC.

### Backup PVC

```bash
NAMESPACE=apps PVC_NAME=postgresql-pvc POD_NAME=postgresql-0 ./backups/pvc-backup.sh
```

If `POD_NAME` is not provided, the script finds a pod that mounts the PVC.

Set `BACKUP_DIR` to change backup location:

```bash
BACKUP_DIR=/backup/pvc NAMESPACE=apps PVC_NAME=redis-pvc ./backups/pvc-backup.sh
```

Backups are compressed tar.gz files. Backups older than 7 days are automatically deleted.

### Restore PVC

Restore a PVC backup to a pod:

```bash
# 1. Ensure the PVC and pod exist
kubectl apply -f workloads/stateful/postgresql.yaml

# 2. Wait for pod to be ready
kubectl wait --for=condition=ready pod/postgresql-0 -n apps --timeout=60s

# 3. Restore from backup
kubectl exec -n apps postgresql-0 -- tar xzf - -C /var/lib/postgresql/data < /root/k3s-backups/pvc/postgresql-pvc-apps-20240212-120000.tar.gz
```

## Backup Strategy

### Recommended Schedule

- **etcd snapshots**: Daily (via cron)
- **PVC backups**: Per application schedule (hourly for critical data, daily for others)

### Cron Example

Add to `/etc/crontab` on the k3s server:

```
0 2 * * * root /path/to/k3s-toybox/backups/etcd-snapshot.sh
```

### Backup Verification

Test restore procedures regularly:

1. Create a test namespace and workload
2. Take a snapshot
3. Make changes
4. Restore from snapshot
5. Verify the changes are gone

## Files

| File | Purpose |
|------|---------|
| `etcd-snapshot.sh` | Create etcd snapshot backup |
| `pvc-backup.sh` | Backup PVC data from a pod |
| `restore-test.sh` | Restore cluster from etcd snapshot |

## Notes

- etcd snapshots include all cluster state (pods, services, configs, secrets)
- PVC backups only include data, not the PVC/PV definitions
- Restore operations stop k3s temporarily
- Test restore procedures in a non-production environment first
