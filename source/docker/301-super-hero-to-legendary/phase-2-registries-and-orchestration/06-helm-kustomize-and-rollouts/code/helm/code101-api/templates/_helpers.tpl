{{- define "code101-api.fullname" -}}
{{- .Release.Name | trunc 40 | trimSuffix "-" -}}
{{- end -}}

{{- define "code101-api.selectorLabels" -}}
app.kubernetes.io/name: code101-api
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "code101-api.labels" -}}
{{ include "code101-api.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
