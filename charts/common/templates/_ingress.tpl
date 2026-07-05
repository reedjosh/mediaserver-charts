{{/* Ingress. Path-based (*arr under /radarr etc.) or host-root (jellyfin). */}}
{{- define "mediaserver.ingress" -}}
{{- if .Values.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Chart.Name }}
  labels:
    {{- include "mediaserver.labels" . | nindent 4 }}
  {{- if or .Values.ingress.annotations .Values.ingress.ssoMiddlewares }}
  annotations:
    {{- with .Values.ingress.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
    {{- if .Values.ingress.ssoMiddlewares }}
    {{- /* Zitadel SSO via oauth2-proxy forwardAuth (homelab-gitops sso/) */}}
    traefik.ingress.kubernetes.io/router.middlewares: sso-oauth-errors@kubernetescrd,sso-oauth-auth@kubernetescrd
    {{- end }}
  {{- end }}
spec:
  ingressClassName: {{ .Values.ingress.className }}
  {{- if .Values.ingress.tls.enabled }}
  tls:
    - hosts:
        - {{ .Values.ingress.host | quote }}
      secretName: {{ .Values.ingress.tls.secretName }}
  {{- end }}
  rules:
    - host: {{ .Values.ingress.host | quote }}
      http:
        paths:
          - path: {{ .Values.ingress.path }}
            pathType: Prefix
            backend:
              service:
                name: {{ .Chart.Name }}
                port:
                  number: {{ .Values.service.port }}
{{- end -}}
{{- end -}}
