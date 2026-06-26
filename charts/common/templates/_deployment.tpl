{{/*
Generic deployment for a single-container linuxserver.io app
(jellyfin / radarr / sonarr / prowlarr). Transmission has its own template
because of the gluetun VPN sidecar.
*/}}
{{- define "mediaserver.deployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Chart.Name }}
  labels:
    {{- include "mediaserver.labels" . | nindent 4 }}
spec:
  replicas: 1
  strategy:
    type: Recreate          # RWX config, never two writers
  selector:
    matchLabels:
      {{- include "mediaserver.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "mediaserver.selectorLabels" . | nindent 8 }}
    spec:
      {{- if .Values.initConfig.enabled }}
      initContainers:
        - name: init-config
          image: docker.io/busybox:1.36
          command: ["/bin/sh", "/init/init.sh"]
          securityContext:
            runAsUser: {{ .Values.puid }}
            runAsGroup: {{ .Values.pgid }}
          volumeMounts:
            - name: init
              mountPath: /init
            - name: config
              mountPath: /config
              subPath: {{ .Chart.Name }}
      {{- end }}
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          envFrom:
            - configMapRef:
                name: {{ .Chart.Name }}-env
          ports:
            - name: http
              containerPort: {{ .Values.port }}
              protocol: TCP
          readinessProbe:
            httpGet:
              path: {{ .Values.probe.path }}
              port: {{ .Values.port }}
            initialDelaySeconds: 10
            periodSeconds: 20
            timeoutSeconds: 20
          volumeMounts:
            {{- include "mediaserver.storageMounts" . | nindent 12 }}
          {{- with .Values.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
      volumes:
        {{- include "mediaserver.storageVolumes" . | nindent 8 }}
        {{- if .Values.initConfig.enabled }}
        - name: init
          configMap:
            name: {{ .Chart.Name }}-init
            defaultMode: 0755
        {{- end }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end -}}
