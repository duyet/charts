{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "zeppelin.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "zeppelin.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "zeppelin.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "zeppelin.labels" -}}
helm.sh/chart: {{ include "zeppelin.chart" . }}
{{ include "zeppelin.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "zeppelin.selectorLabels" -}}
app.kubernetes.io/name: {{ include "zeppelin.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "zeppelin.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "zeppelin.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the role name to use
*/}}
{{- define "zeppelin.roleName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "zeppelin.fullname" .) .Values.serviceAccount.name }}-role
{{- else }}
{{- default "default" .Values.serviceAccount.name }}-role
{{- end }}
{{- end }}

{{/*
Create the name of the role binding name to use
*/}}
{{- define "zeppelin.roleBindingName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "zeppelin.fullname" .) .Values.serviceAccount.name }}-role-binding
{{- else }}
{{- default "default" .Values.serviceAccount.name }}-role-binding
{{- end }}
{{- end }}

{{/*
'serviceDomain' is a Domain name to use for accessing Zeppelin UI.
Should point IP address of 'zeppelin-server' service.
*/}}
{{- define "zeppelin.serviceDomain" -}}
{{- if .Values.ingress.enabled }}
{{- with (first .Values.ingress.hosts) }}
{{- .host }}
{{- end }}
{{- else }}
{{- default .Values.env.SERVICE_DOMAIN (include "zeppelin.fullname" .) }}
{{- end }}
{{- end }}
