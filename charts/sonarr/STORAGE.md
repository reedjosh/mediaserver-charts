# Sonarr config storage

The umbrella chart uses `sonarr-config-local` (`local-path`, 5Gi request) for
Sonarr configuration, with the existing `sonarr/` subdirectory layout. Both the
pod node selector and the provisioned PV affinity place it on `jayrdl3803`, the
NFS server node. `/data` remains on the shared NFS claim. Local-path capacity
requests are not filesystem quotas.

The PVC is protected against automatic Argo pruning/deletion and Helm removal.
The initial PV was also set to reclaim policy `Retain`; repeat that step if the
claim is ever deliberately reprovisioned. Node loss still requires recovery.
Do not delete the PVC to troubleshoot application errors.

## Migration performed

Sonarr was stopped through its s6 supervisor before copying the entire NFS
`mediaserver-config/sonarr` tree to the new claim. All 274 files were compared
with SHA-256 before opening the copied databases; SQLite integrity checks passed
for both databases and all 18 series were present. The NFS source is retained,
unchanged, as a cutover rollback copy. It becomes stale after local writes begin.
The running image digest is pinned to avoid a simultaneous version upgrade.

## Backup and rollback

Keep scheduled Sonarr backups on NFS at `/data/backups/sonarr`, not just on the
local claim. These backups protect against local-volume loss, but not loss of
the NFS node itself; retain an off-node backup for that failure mode.

To roll back without losing post-cutover updates, stop Sonarr first and take a
fresh backup of local config. Restore that backup into the NFS `sonarr/` subtree
before changing `storage.configClaim` to `mediaserver-config`. Never run two
Sonarr processes against either database. Reverting only the claim setting
would use the stale cutover copy and lose later changes.
