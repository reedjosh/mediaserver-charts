# mediaserver-charts

Helm charts for a self-hosted media stack on Kubernetes — Jellyfin, Radarr,
Sonarr, Prowlarr, and Transmission (with a gluetun WireGuard sidecar).

This is a from-scratch rework of the all-in-one
[`kubealex/k8s-mediaserver-operator`](https://github.com/kubealex/k8s-mediaserver-operator)
chart, split into **one chart per app** on a shared `common` library chart, with
an umbrella chart that ties them together. The headline change is the storage
layout (see below), which fixes duplicate-file growth from non-hardlinked imports.

## Layout

```
charts/
  common/         library chart — labels, storage volumes/mounts, deployment/
                  service/ingress/configmap templates shared by the app charts
  jellyfin/       \
  radarr/          |  one application chart per app, each depending on common
  sonarr/          |
  prowlarr/        |
  transmission/   /   (bespoke: adds the gluetun VPN sidecar)
  reencoder/      CronJob that re-encodes oversized x264 media to HEVC/AV1
  mediaserver/    umbrella — depends on all apps, owns the shared PVCs
```

## Library re-encoder

`reencoder` is a `CronJob` that periodically finds oversized legacy (x264) files
and transcodes them to **AV1** (default; `encode.codec: hevc` to switch) to
reclaim space. Since the source is x264, this is a single clean lossy generation.
It's **idempotent** (already-HEVC/AV1 files are skipped), processes
a **bounded batch** per run, **skips HDR/4K** by default, and **never hard-deletes**
— originals are parked in `/data/.reencode-trash` for review. CPU software encode
out of the box; set `gpu.enabled: true` (+ a GPU-capable ffmpeg image) for NVENC/VAAPI.

> It rewrites files in place, so Radarr/Sonarr will see changed files on their
> next scan — let them rescan. Disabled by default in the umbrella.

## Storage model (the important part)

Two ReadWriteMany PVCs on an NFS storage class:

- **`mediaserver-config`** — small, precious app state. Each app mounts its own
  subdir at `/config`.
- **`mediaserver-data`** — media **and** torrents, mounted as a *single* volume
  at `/data` (`/data/media/{movies,tv}` + `/data/torrents`).

Mounting media and downloads under one mount is what lets Radarr/Sonarr
**hardlink** completed downloads into the library instead of copying them — no
more duplicate files. (The old layout mounted `/downloads` and `/movies` as
separate subPaths, which are separate devices to the kernel, so imports fell back
to copying.) Turn on *Settings → Media Management → Use Hardlinks instead of
Copy* in Radarr/Sonarr, and point download clients + root folders inside `/data`.

> Size requests on these PVCs are advisory — the nfs-subdir provisioner does not
> enforce them. To guarantee headroom, set an XFS project quota on the data
> directory on the NFS host.

## Secrets

The Transmission VPN private key is **never** committed. Create it out of band:

```sh
kubectl -n mediaserver create secret generic transmission-vpn \
  --from-literal=WIREGUARD_PRIVATE_KEY=xxxxxxxxxxxxxxxxxxxx
```

Set the non-secret VPN fields (`endpointIP`, `publicKey`, `addresses`, …) in a
local values override, not in this repo.

## Install

```sh
# resolve the file:// dependencies (common -> apps -> umbrella)
for c in common jellyfin radarr sonarr prowlarr transmission mediaserver; do
  helm dependency update charts/$c
done

helm upgrade --install mediaserver charts/mediaserver \
  -n mediaserver --create-namespace \
  -f my-values.yaml          # ingress hosts, VPN config, etc.
```

Individual apps can also be installed on their own:

```sh
helm dependency update charts/radarr
helm upgrade --install radarr charts/radarr -n mediaserver
```
