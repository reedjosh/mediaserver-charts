{{/*
Common labels applied to every object.
Rendered in the context of the *app* chart, so .Chart is the app chart.
*/}}
{{- define "mediaserver.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "mediaserver.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | default .Values.image.tag | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: mediaserver
{{- end -}}

{{/*
Selector labels. Unlike the upstream monolith (which gave every app the same
name label), each app carries its own chart name here so selectors don't collide.
*/}}
{{- define "mediaserver.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
PUID / PGID config map data (linuxserver.io images run as this uid/gid).
*/}}
{{- define "mediaserver.idEnv" -}}
PUID: {{ .Values.puid | quote }}
PGID: {{ .Values.pgid | quote }}
TZ: {{ .Values.tz | quote }}
{{- end -}}

{{/*
Pod volumes for the shared NFS storage.

  - "config" : the per-app config PVC (RWX), one subdir per app.
  - "data"   : the single media+downloads PVC (RWX), mounted whole so radarr/
               sonarr can hardlink imports across media/ and torrents/.
               Only mounted when .Values.storage.mountData is true.
*/}}
{{- define "mediaserver.storageVolumes" -}}
- name: config
  persistentVolumeClaim:
    claimName: {{ .Values.storage.configClaim }}
{{- if .Values.storage.mountData }}
- name: data
  persistentVolumeClaim:
    claimName: {{ .Values.storage.dataClaim }}
{{- end }}
{{- end -}}

{{/*
Volume mounts matching mediaserver.storageVolumes.
config is sub-pathed per app; data is a single mount (no subPath) on purpose.
*/}}
{{- define "mediaserver.storageMounts" -}}
- name: config
  mountPath: /config
  subPath: {{ .Chart.Name }}
{{- if .Values.storage.mountData }}
- name: data
  mountPath: /data
{{- end }}
{{- end -}}
