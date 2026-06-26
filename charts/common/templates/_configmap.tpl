{{/*
ConfigMaps for an app:
  - <name>-env  : PUID/PGID/TZ for the linuxserver image (always)
  - <name>-init : default config.xml (UrlBase) + seed script, when initConfig
                  is enabled (path-based *arr apps that serve under a sub-path)
*/}}
{{- define "mediaserver.configMaps" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Chart.Name }}-env
  labels:
    {{- include "mediaserver.labels" . | nindent 4 }}
data:
  {{- include "mediaserver.idEnv" . | nindent 2 }}
{{- if .Values.initConfig.enabled }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Chart.Name }}-init
  labels:
    {{- include "mediaserver.labels" . | nindent 4 }}
data:
  config.xml: |
    <Config>
      <UrlBase>{{ .Values.ingress.path }}</UrlBase>
    </Config>
  init.sh: |
    #!/bin/sh
    # Seed a default config.xml (with the correct UrlBase) on first start only.
    if [ ! -f /config/config.xml ]; then
      cp /init/config.xml /config/config.xml
      echo "seeded default config.xml with UrlBase {{ .Values.ingress.path }}"
    fi
{{- end -}}
{{- end -}}
