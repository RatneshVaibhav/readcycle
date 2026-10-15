{{- define "readcycle.name" -}}{{ .Release.Name | trunc 50 | trimSuffix "-" }}{{- end -}}

{{- define "readcycle.labels" -}}
app.kubernetes.io/name: readcycle
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "readcycle.selector" -}}
app.kubernetes.io/name: readcycle
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}

{{- define "readcycle.image" -}}
{{ printf "%s/%s/readcycle-%s:%s" .root.Values.image.registry .root.Values.image.owner .name .root.Values.image.tag }}
{{- end -}}

{{- define "readcycle.dbHost" -}}
{{ .Values.database.host | default (printf "%s-postgres" (include "readcycle.name" .)) }}
{{- end -}}

{{- define "readcycle.restricted" -}}
allowPrivilegeEscalation: false
capabilities:
  drop: ["ALL"]
{{- end -}}
