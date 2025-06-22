{{/*
Expand the name of the chart.
*/}}
{{- define "python-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "python-app.fullname" -}}
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
{{- define "python-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "python-app.labels" -}}
helm.sh/chart: {{ include "python-app.chart" . }}
{{ include "python-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "python-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "python-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "python-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "python-app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get environment-specific replica count
*/}}
{{- define "python-app.replicaCount" -}}
{{- $env := .Values.environment | default "dev" }}
{{- if hasKey .Values.replicaCounts $env }}
{{- index .Values.replicaCounts $env }}
{{- else }}
{{- .Values.replicaCount }}
{{- end }}
{{- end }}

{{/*
Get environment-specific resources
*/}}
{{- define "python-app.resources" -}}
{{- $env := .Values.environment | default "dev" }}
{{- $defaultResources := .Values.resources }}
{{- if and (hasKey .Values.resources "environments") (hasKey .Values.resources.environments $env) }}
{{- $envResources := index .Values.resources.environments $env }}
{{- merge $defaultResources $envResources }}
{{- else }}
{{- $defaultResources }}
{{- end }}
{{- end }}

{{/*
Get environment-specific autoscaling configuration
*/}}
{{- define "python-app.autoscaling" -}}
{{- $env := .Values.environment | default "dev" }}
{{- $defaultAutoscaling := .Values.autoscaling }}
{{- if and (hasKey .Values.autoscaling "environments") (hasKey .Values.autoscaling.environments $env) }}
{{- $envAutoscaling := index .Values.autoscaling.environments $env }}
{{- merge $defaultAutoscaling $envAutoscaling }}
{{- else }}
{{- $defaultAutoscaling }}
{{- end }}
{{- end }}

{{/*
Get environment-specific Redis configuration
*/}}
{{- define "python-app.redis" -}}
{{- $env := .Values.environment | default "dev" }}
{{- $defaultRedis := .Values.redis }}
{{- if and (hasKey .Values.redis "environments") (hasKey .Values.redis.environments $env) }}
{{- $envRedis := index .Values.redis.environments $env }}
{{- merge $defaultRedis $envRedis }}
{{- else }}
{{- $defaultRedis }}
{{- end }}
{{- end }}

{{/*
Get environment-specific environment variables
*/}}
{{- define "python-app.env" -}}
{{- $env := .Values.environment | default "dev" }}
{{- $defaultEnv := .Values.env }}
{{- if and (hasKey .Values.env "environments") (hasKey .Values.env.environments $env) }}
{{- $envVars := index .Values.env.environments $env }}
{{- merge $defaultEnv $envVars }}
{{- else }}
{{- $defaultEnv }}
{{- end }}
{{- end }}

{{/*
Get environment-specific probes
*/}}
{{- define "python-app.probes" -}}
{{- $env := .Values.environment | default "dev" }}
{{- $defaultProbes := .Values.probes }}
{{- if and (hasKey .Values.probes "environments") (hasKey .Values.probes.environments $env) }}
{{- $envProbes := index .Values.probes.environments $env }}
{{- merge $defaultProbes $envProbes }}
{{- else }}
{{- $defaultProbes }}
{{- end }}
{{- end }}

{{/*
Get environment-specific monitoring configuration
*/}}
{{- define "python-app.monitoring" -}}
{{- $env := .Values.environment | default "dev" }}
{{- $defaultMonitoring := .Values.monitoring }}
{{- if and (hasKey .Values.monitoring "environments") (hasKey .Values.monitoring.environments $env) }}
{{- $envMonitoring := index .Values.monitoring.environments $env }}
{{- merge $defaultMonitoring $envMonitoring }}
{{- else }}
{{- $defaultMonitoring }}
{{- end }}
{{- end }} 