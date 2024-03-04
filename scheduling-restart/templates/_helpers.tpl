{{/*
Expand the name of the chart.
*/}}
{{- define "scheduling-restart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "scheduling-restart.fullname" -}}
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
{{- define "scheduling-restart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "scheduling-restart.labels" -}}
helm.sh/chart: {{ include "scheduling-restart.chart" . }}
{{ include "scheduling-restart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "scheduling-restart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "scheduling-restart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "scheduling-restart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "scheduling-restart.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Schedule cronjob with some presets

e.g. 
  - every 5 minutes
  - every 1 hour
  - 0 * * * * (every hour)
  - 0 0 * * * (every day)
*/}}
{{- define "scheduling-restart.schedule" -}}
{{- $schedule := .Values.schedule | default "0 * * * *" -}}
{{- if has $schedule (list "every 5 minutes") -}}
*/5 * * * *
{{- else if has $schedule (list "@1 hour" "every hour" "@every 1 hour" "@every 1 hours") -}}
0 * * * *
{{- else if has $schedule (list "@every day" "@everyday" "@daily") -}}
0 0 * * *
{{- else if has $schedule (list "@every week" "@everyweek" "@weekly") -}}
0 0 * * 0
{{- else if has $schedule (list "@every month" "@monthly") -}}
0 0 1 * *
{{- else -}}
{{- $schedule -}}
{{- end }}
{{- end }}

{{/*
Get namespace from .Values.restarts config

deployment/airflow@my-namespace -> my-namespace
*/}}
{{- define "scheduling-restart.get-namespace" -}}
{{- $parts := split "@" . }}
{{- $parts._1 | default "" }}
{{- end }}

{{/*
Get deployment name from .Values.restarts config

deployment/airflow@my-namespace -> deployment/airflow
*/}}
{{- define "scheduling-restart.get-deployment-name" -}}
{{- $parts := split "@" . }}
{{- $parts._0 | default "" }}
{{- end }}

{{/*
Generate container name from .Values.restarts config

deployment/something -> deployment-something
deployment/something@namespace -> deployment-something-namespace
*/}}
{{- define "scheduling-restart.container-name" -}}
{{- $name := include "scheduling-restart.get-deployment-name" . }}
{{- $namespace := include "scheduling-restart.get-namespace" . }}
{{- $name | replace "/" "-" }}{{ if $namespace }}-{{ $namespace }}{{ end }}
{{- end }}

