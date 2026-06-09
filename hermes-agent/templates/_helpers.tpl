{{/*
Expand the name of the chart.
*/}}
{{- define "hermes-agent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "hermes-agent.fullname" -}}
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
{{- define "hermes-agent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "hermes-agent.labels" -}}
helm.sh/chart: {{ include "hermes-agent.chart" . }}
{{ include "hermes-agent.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: hermes-agent
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "hermes-agent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hermes-agent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "hermes-agent.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "hermes-agent.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Name of the Secret holding credentials (chart-managed or user-provided).
*/}}
{{- define "hermes-agent.secretName" -}}
{{- if .Values.secrets.existingSecret }}
{{- .Values.secrets.existingSecret }}
{{- else }}
{{- include "hermes-agent.fullname" . }}
{{- end }}
{{- end }}

{{/*
Name of the data (core agent state) PersistentVolumeClaim.
*/}}
{{- define "hermes-agent.dataClaimName" -}}
{{- if .Values.persistence.data.existingClaim }}
{{- .Values.persistence.data.existingClaim }}
{{- else }}
{{- printf "%s-data" (include "hermes-agent.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Name of the workspace (working directory) PersistentVolumeClaim.
*/}}
{{- define "hermes-agent.workspaceClaimName" -}}
{{- if .Values.persistence.workspace.existingClaim }}
{{- .Values.persistence.workspace.existingClaim }}
{{- else }}
{{- printf "%s-workspace" (include "hermes-agent.fullname" .) }}
{{- end }}
{{- end }}

{{/*
The agent working directory path (terminal.cwd). When the workspace volume is
enabled, the agent operates inside its mountPath; otherwise it falls back to the
core data home.
*/}}
{{- define "hermes-agent.workingDir" -}}
{{- if .Values.persistence.workspace.enabled }}
{{- .Values.persistence.workspace.mountPath }}
{{- else }}
{{- .Values.persistence.data.mountPath }}
{{- end }}
{{- end }}

{{/*
Render the agent config.yaml body from .Values.config.values.
- Injects terminal.cwd -> the workspace mountPath when the workspace volume is
  enabled, so the agent operates inside its persistent working directory.
- Prunes empty top-level sections (model, providers, custom_providers,
  fallback_providers, display, ...) so unset optional blocks never reach the
  rendered config.yaml.
Secrets are referenced as ${ENV_VAR} placeholders in the values and expanded by
Hermes at runtime from the chart-managed Secret (see .Values.secrets) — they are
never written into this ConfigMap.
*/}}
{{- define "hermes-agent.config" -}}
{{- $src := deepCopy .Values.config.values -}}
{{- if .Values.persistence.workspace.enabled -}}
{{- $terminal := default (dict) (get $src "terminal") -}}
{{- $_ := set $terminal "cwd" .Values.persistence.workspace.mountPath -}}
{{- $_ := set $src "terminal" $terminal -}}
{{- end -}}
{{- $out := dict -}}
{{- range $k, $v := $src -}}
{{- if not (empty $v) -}}
{{- $_ := set $out $k $v -}}
{{- end -}}
{{- end -}}
{{- toYaml $out -}}
{{- end }}

{{/*
Ingress API version detection.
*/}}
{{- define "hermes-agent.ingressApiVersion" -}}
{{- $kubeVersion := .Capabilities.KubeVersion.GitVersion -}}
{{- if semverCompare ">=1.19-0" $kubeVersion -}}
networking.k8s.io/v1
{{- else if semverCompare ">=1.14-0" $kubeVersion -}}
networking.k8s.io/v1beta1
{{- else -}}
extensions/v1beta1
{{- end }}
{{- end }}
