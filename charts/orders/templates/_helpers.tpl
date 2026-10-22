{{/* Common labels */}}
{{- define "orders.labels" -}}
app.kubernetes.io/part-of: shipyard
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{/* Full image reference; fails if the tag is missing */}}
{{- define "orders.image" -}}
{{ .root.Values.image.registry }}/shipyard/{{ .name }}:{{ required "image.tag is required (git SHA)" .root.Values.image.tag }}
{{- end }}

{{/* Env vars shared by api and worker */}}
{{- define "orders.commonEnv" -}}
- name: AWS_REGION
  value: {{ .Values.aws.region | quote }}
- name: QUEUE_URL
  value: {{ required "queue.url is required" .Values.queue.url | quote }}
- name: PGHOST
  value: {{ required "database.host is required" .Values.database.host | quote }}
- name: PGPORT
  value: {{ .Values.database.port | quote }}
- name: PGDATABASE
  value: {{ .Values.database.name | quote }}
- name: PGUSER
  valueFrom:
    secretKeyRef:
      name: {{ .Values.database.secretName }}
      key: username
- name: PGPASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.database.secretName }}
      key: password
- name: DB_SSL
  value: {{ .Values.database.sslMode | quote }}
- name: APP_VERSION
  value: {{ .Values.image.tag | quote }}
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: NODE_NAME
  valueFrom:
    fieldRef:
      fieldPath: spec.nodeName
{{- end }}

{{/* Pod-level security */}}
{{- define "orders.podSecurityContext" -}}
runAsNonRoot: true
runAsUser: 1000 # the "node" user; numeric so Kubernetes can verify non-root
runAsGroup: 1000
seccompProfile:
  type: RuntimeDefault
{{- end }}

{{/* Container-level security */}}
{{- define "orders.containerSecurityContext" -}}
allowPrivilegeEscalation: false
readOnlyRootFilesystem: true
capabilities:
  drop: ["ALL"]
{{- end }}