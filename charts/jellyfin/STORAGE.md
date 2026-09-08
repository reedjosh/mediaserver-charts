# Jellyfin local config

The umbrella chart mounts `jellyfin-config-local` (local-path, 20Gi request)
under `/config`, retaining the `jellyfin/` subdirectory. Pod and PV placement
are on `jayrdl3803`. Its `/var/lib/local-path-provisioner` resides on the root
LV backed by `/dev/sda`: a RAID1 pair of 480GB SATA SSDs, verified using findmnt,
lsblk and ssacli. Media remains on `/dev/sdb` (14TB HDD mirror) over the existing
NFS `/tv` and `/movies` mounts. Local-path requests are not quotas.

The PVC is protected against automatic Argo prune/delete and Helm uninstall.
The provisioned PV is also set to Retain; repeat this if deliberately creating
a replacement PV. This is node-local storage, not replicated cluster storage.

Migration stops Jellyfin's s6 service before copying its whole config tree,
including users, watched history, metadata and settings. The existing image
digest is pinned so the move does not also upgrade Jellyfin. The original NFS
config remains a cutover backup; it becomes stale after local writes begin.

Before any rollback, stop Jellyfin and back up the current local config.
Restore that fresh copy to the NFS subtree before changing configClaim back
to mediaserver-config. Using the untouched cutover copy would lose subsequent
watched history and other changes. Never run two processes on the same DB.
Ongoing off-node backup scheduling is separate from this storage migration;
the retained NFS copy is not an automatically updated backup.
