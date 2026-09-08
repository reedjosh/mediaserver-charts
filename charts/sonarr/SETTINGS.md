# Declarative Sonarr settings

The umbrella chart enables `sonarr.declarativeSettings`. An Argo CD PostSync
Job reconciles these settings using Sonarr's supported API:

- Series folder format: `{Series TitleYear}`.
- Kodi (XBMC) / Emby metadata consumer enabled.
- Series and episode NFO metadata enabled; image output disabled so Jellyfin
  continues to manage artwork.

Change the desired values in `charts/sonarr/values.yaml` or override them in
the umbrella values. Sonarr stores these settings in its database, not
`config.xml`; merely mounting a config file cannot configure them.

The job reads the existing API key from the read-only config mount. No key is
committed, passed in command-line arguments, or logged. The job runs on Sonarr's
node, updates only owned fields, preserves unrelated settings, verifies the
saved values, and fails on ambiguous consumers or unsupported fields. It never
opens the SQLite database. Failed jobs remain available for diagnostics.

This reconciles on full Argo CD sync, not continuously. A UI edit can remain
until the next sync; selective sync does not execute hooks. Outside Argo CD,
run the rendered job explicitly after Sonarr becomes healthy.

Changing the folder format does not rename existing folders or move files.
Existing series need a separate, intentional Sonarr-managed path migration.
Enabling NFO output also does not repair incorrect Sonarr identities: identify
ambiguous shows correctly in Sonarr first. To backfill NFO files, use a Sonarr
series refresh; inspect `tvshow.nfo` provider IDs before refreshing Jellyfin.
Jellyfin reads the local NFOs, reducing reliance on title-only matching.
