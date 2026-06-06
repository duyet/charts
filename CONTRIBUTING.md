# Contributing to Helm Charts

Thank you for contributing to this collection of Helm charts! This document provides guidelines and standards for maintaining consistency and quality across all charts.

## Philosophy

**Simplicity without losing power.** These charts should guide users toward production-ready deployments while maintaining flexibility for customization.

## Chart Standards

### 1. API Version

- **Use Helm v2 API** (`apiVersion: v2`) for all charts
- Include semantic versioning in `Chart.yaml`
- Specify `appVersion` to indicate the application version

### 2. Template Formatting

#### Indentation
- **Always use `nindent`** instead of `indent | trim`
  ```yaml
  # Good
  {{- with .Values.resources }}
  resources:
    {{- toYaml . | nindent 10 }}
  {{- end }}

  # Bad
  {{- with .Values.resources }}
  resources:
{{ toYaml . | indent 10 | trim }}
  {{- end }}
  ```

#### Value Quoting
- **Always quote** string values in environment variables
  ```yaml
  # Good
  - name: MY_VAR
    value: {{ .Values.myVar | quote }}

  # Bad
  - name: MY_VAR
    value: {{ .Values.myVar }}
  ```

### 3. Configuration Standards

#### Required Fields in values.yaml

Every chart should include:
```yaml
# Number of replicas
replicaCount: 1

image:
  repository: <image-name>
  tag: <version>
  pullPolicy: IfNotPresent

# Resource limits and requests
resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

# Service account
serviceAccount:
  create: true
  annotations: {}
  name: ""

# Security context
podSecurityContext: {}
securityContext: {}

# Node scheduling
nodeSelector: {}
tolerations: []
affinity: {}

# Pod annotations
podAnnotations: {}
```

#### Never Hard-Code These Values

- `replicas` - always use `.Values.replicaCount`
- `imagePullPolicy` - always use `.Values.image.pullPolicy`
- `serviceAccount` - always support custom service accounts
- `resources` - always make configurable via `.Values.resources`

### 4. Config Change Detection

**Always** add checksum annotations for ConfigMaps and Secrets to trigger pod restarts on configuration changes:

```yaml
template:
  metadata:
    annotations:
      checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
      checksum/secret: {{ include (print $.Template.BasePath "/secret.yaml") . | sha256sum }}
```

### 5. Documentation

#### Helm-Docs

- Use `helm-docs` comments for all values
- Format: `# key -- description`
  ```yaml
  # image.repository -- The image repository
  repository: myapp
  # image.tag -- The image tag
  tag: 1.0.0
  ```

#### README.md

- Auto-generated via `helm-docs`
- Include usage examples
- Document any prerequisites
- Explain non-obvious configuration options

#### NOTES.txt

- Provide post-installation instructions
- Show how to access the deployed application
- Include relevant kubectl commands
- Keep it concise (under 25 lines)

### 6. Security Practices

#### Default Security Context

Provide secure defaults:
```yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
    - ALL
```

#### Secrets Management

- Never commit secrets in `values.yaml`
- Support `existingSecret` parameter
- Document secret creation in README

#### Network Policies

- Include optional NetworkPolicy template
- Disabled by default
- Document required network access

### 7. Production Readiness

#### Health Checks

Always include when applicable:
```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

#### Resource Limits

- Always define default resource limits
- Base on actual application requirements
- Document in README if they need tuning

#### Pod Disruption Budgets

For production-critical services:
```yaml
{{- if .Values.podDisruptionBudget.enabled }}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "chart.fullname" . }}
spec:
  minAvailable: {{ .Values.podDisruptionBudget.minAvailable }}
  selector:
    matchLabels:
      {{- include "chart.selectorLabels" . | nindent 6 }}
{{- end }}
```

### 8. Testing

#### Helm Lint

- Run `helm lint` before committing
- Fix all warnings and errors
- Use `.helmignore` to exclude unnecessary files

#### Chart Testing

- CI automatically tests charts using `chart-testing`
- Tests across multiple Kubernetes versions (1.27-1.31)
- Include test pods in `templates/tests/`

#### Local Testing

```bash
# Lint chart
helm lint ./chart-name

# Template chart
helm template test ./chart-name

# Install locally
helm install test ./chart-name --dry-run --debug

# Test with Kind
kind create cluster
helm install test ./chart-name
helm test test
```

## Submission Process

### 1. Before Submitting

- [ ] Run `helm lint` on your chart
- [ ] Update chart version in `Chart.yaml` (following semver)
- [ ] Run `./doc.sh` to regenerate README.md
- [ ] Test installation in a Kind cluster
- [ ] Review diffs for unintended changes

### 2. Chart Versioning

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** - Incompatible API changes
- **MINOR** - New functionality (backward compatible)
- **PATCH** - Bug fixes (backward compatible)

Update `appVersion` when the application version changes.

### 3. Commit Messages

Use clear, descriptive commit messages:

```
<chart-name>: <short description>

- Detailed change 1
- Detailed change 2
- Fix #issue-number
```

Examples:
```
commento: make replicas configurable

- Add replicaCount to values.yaml
- Replace hard-coded replicas: 1 with template
- Allows users to scale the deployment

amundsen: standardize indentation to nindent

- Replace all 'indent | trim' with 'nindent'
- Improves template readability and consistency
```

### 4. Pull Request

- Link to related issues
- Describe what changed and why
- Include testing notes
- Wait for CI to pass

## Questions?

Feel free to open an issue for:
- Clarification on standards
- Suggestions for improvements
- Help with chart development

Thank you for helping make these charts better!
