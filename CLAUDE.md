# CLAUDE.md - Project Philosophy & Development Guide

> "Simplicity is the ultimate sophistication." - Leonardo da Vinci

This document captures the soul of this Helm charts repository. Read this first before contributing.

## The Vision

This repository is a collection of **production-ready Helm charts** that guide users toward secure, scalable deployments while maintaining the flexibility to customize for their needs.

We don't just make charts that work—we make charts that are **inevitable**. Every configuration option should feel natural. Every default should be sensible. Every template should be elegant.

## Core Principles

### 1. **Simplicity Without Losing Power**

The best solutions are simple but not simplistic. Our charts should:
- Provide sensible defaults that work out of the box
- Expose configuration for production requirements
- Hide complexity without limiting capability
- Make the common case easy and the advanced case possible

**Example**: Default to 1 replica for simplicity, but always make `replicaCount` configurable for production scaling.

### 2. **Consistency is Kindness**

When users move between charts in this repository, they should feel at home. This means:
- Uniform `values.yaml` structure across all charts
- Consistent naming conventions
- Shared patterns for common features (service accounts, security contexts, etc.)
- Modern, standardized template syntax (`nindent`, not `indent | trim`)

**Why it matters**: Cognitive load is a user experience issue. Consistency reduces friction.

### 3. **Security by Default**

Security isn't optional. Every chart should:
- Use non-root users by default where possible
- Support (and encourage) security contexts
- Never hard-code secrets
- Always support `existingSecret` patterns
- Provide resource limits as defaults

**Philosophy**: Make the secure path the easy path.

### 4. **Production-Ready from Day One**

These charts aren't experiments. They're tools for running real workloads. This means:
- Config changes trigger automatic pod restarts (via checksum annotations)
- Health checks are included and sensible
- Resource limits prevent runaway processes
- Support for PodDisruptionBudgets on critical services
- Clear NOTES.txt with post-installation guidance

### 5. **No Magic, Only Clarity**

Templates should be readable. Defaults should be documented. Behavior should be predictable.

- Use clear variable names (`.Values.replicaCount`, not `.Values.reps`)
- Comment complex logic
- Document every value with `helm-docs` annotations
- Write NOTES.txt that actually helps users

## Development Standards

### Semantic Commits

**We use semantic commit messages.** This isn't bureaucracy—it's communication.

#### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

#### Types

- **feat**: New feature or capability
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Formatting, whitespace (not CSS)
- **refactor**: Code restructuring without behavior change
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Maintenance tasks, dependency updates
- **ci**: CI/CD pipeline changes
- **revert**: Reverting a previous commit

#### Scope

The chart name or area affected:
- `amundsen`, `commento`, `pgbouncer`, etc.
- `ci`, `docs`, `all` for cross-cutting changes

#### Examples

```
feat(commento): add configurable replica count

Previously, commento deployment hard-coded replicas: 1, preventing
users from scaling the application. This change adds replicaCount
to values.yaml with a default of 1, maintaining backward compatibility
while enabling production scaling.

Closes #42
```

```
fix(amundsen): add missing imagePullPolicy configuration

The frontend, metadata, and search services hard-coded
imagePullPolicy: Always, causing unnecessary registry pulls.
Now configurable via values.yaml with IfNotPresent default.

Breaking change: None (adds new field with sensible default)
```

```
chore(all): migrate to Helm v2 API

Migrates all v1 charts to v2 API:
- amundsen: 1.0.0 -> 1.1.0
- commento: 0.1.0 -> 0.2.0
- pgbouncer: 1.0.8 -> 1.1.0
- spark-shuffle: 0.1.0 -> 0.2.0

Moves dependencies from requirements.yaml to Chart.yaml.
Updates appVersion to reflect actual application versions.
```

```
docs: add CLAUDE.md and CONTRIBUTING.md

Establishes project philosophy and contribution guidelines.
Provides semantic commit standards and chart best practices.
```

#### Commit Message Guidelines

1. **Use imperative mood** in subject: "add feature" not "added feature"
2. **Don't end subject with period**
3. **Limit subject to 50 characters** (soft limit, 72 hard limit)
4. **Wrap body at 72 characters**
5. **Separate subject from body with blank line**
6. **Use body to explain what and why, not how**
7. **Reference issues and PRs** in footer

### Template Standards

#### Always Use `nindent`

```yaml
# Good ✓
{{- with .Values.resources }}
resources:
  {{- toYaml . | nindent 10 }}
{{- end }}

# Bad ✗
{{- with .Values.resources }}
resources:
{{ toYaml . | indent 10 | trim }}
{{- end }}
```

#### Always Quote String Values

```yaml
# Good ✓
env:
  - name: DATABASE_URL
    value: {{ .Values.database.url | quote }}

# Bad ✗
env:
  - name: DATABASE_URL
    value: {{ .Values.database.url }}
```

#### Never Hard-Code These

- `replicas` - always use `.Values.replicaCount`
- `imagePullPolicy` - always use `.Values.image.pullPolicy`
- `serviceAccountName` - always use service account helper
- Resources - always make configurable

#### Always Add Config Checksums

```yaml
template:
  metadata:
    annotations:
      checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
```

### Values.yaml Structure

Follow this order for consistency:

```yaml
# 1. Replica configuration
replicaCount: 1

# 2. Image configuration
image:
  repository: myapp
  tag: 1.0.0
  pullPolicy: IfNotPresent

# 3. Service account
serviceAccount:
  create: true
  annotations: {}
  name: ""

# 4. Pod annotations and labels
podAnnotations: {}
podLabels: {}

# 5. Security contexts
podSecurityContext: {}
securityContext: {}

# 6. Service configuration
service:
  type: ClusterIP
  port: 80

# 7. Ingress
ingress:
  enabled: false
  annotations: {}
  hosts: []
  tls: []

# 8. Resources
resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

# 9. Autoscaling (if applicable)
autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 10

# 10. Node scheduling
nodeSelector: {}
tolerations: []
affinity: {}

# 11. Application-specific configuration
# (varies by chart)
```

### Chart Versioning

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (x.0.0): Breaking changes, incompatible API changes
- **MINOR** (0.x.0): New features, backward compatible
- **PATCH** (0.0.x): Bug fixes, backward compatible

**When to bump**:

| Change | Version Bump | Example |
|--------|--------------|---------|
| Add new configurable feature | MINOR | Add PDB support |
| Fix bug without breaking compatibility | PATCH | Fix checksum annotation |
| Change default that could affect users | MAJOR | Change default replica count |
| Add required new value | MAJOR | Require secret name |
| Add optional new value | MINOR | Add optional NetworkPolicy |
| Template formatting (no behavior change) | PATCH | Migrate to nindent |
| Helm API v1 → v2 migration | MINOR | Chart.yaml apiVersion change |

### Documentation

#### helm-docs Comments

Every value must have a comment:

```yaml
# image.repository -- The container image repository
repository: myapp

# image.tag -- The container image tag
tag: 1.0.0

# image.pullPolicy -- Image pull policy (IfNotPresent, Always, Never)
pullPolicy: IfNotPresent
```

#### NOTES.txt

Make it useful. Show:
1. How to verify the deployment
2. How to access the service
3. Next steps (if any)
4. Relevant kubectl commands

```
{{- if .Values.ingress.enabled }}
1. Access {{ include "chart.fullname" . }} at:
{{- range .Values.ingress.hosts }}
   http{{ if $.Values.ingress.tls }}s{{ end }}://{{ .host }}
{{- end }}
{{- else }}
1. Get the application URL by running:
   export POD_NAME=$(kubectl get pods -n {{ .Release.Namespace }} -l "app.kubernetes.io/name={{ include "chart.name" . }}" -o jsonpath="{.items[0].metadata.name}")
   kubectl port-forward -n {{ .Release.Namespace }} $POD_NAME 8080:80
   echo "Visit http://127.0.0.1:8080"
{{- end }}
```

## Testing Workflow

### Before Committing

```bash
# 1. Lint your chart
helm lint ./chart-name

# 2. Template and review
helm template test ./chart-name --debug

# 3. Dry run
helm install test ./chart-name --dry-run

# 4. Regenerate docs (if helm-docs available)
helm-docs

# 5. Check git diff
git diff
```

### Testing Locally

```bash
# Create Kind cluster
kind create cluster --name chart-test

# Install chart
helm install test ./chart-name

# Run tests (if available)
helm test test

# Check pods
kubectl get pods

# Check logs
kubectl logs -l app.kubernetes.io/name=chart-name

# Cleanup
helm uninstall test
kind delete cluster --name chart-test
```

## The Review Process

### For Contributors

1. **Read CONTRIBUTING.md** - Know the standards
2. **Use semantic commits** - Communicate clearly
3. **Test thoroughly** - Verify locally
4. **Update version** - Follow semver
5. **Regenerate docs** - Keep README current
6. **Write clear PR description** - Explain the why

### For Reviewers

1. **Check semantic commits** - Good messages matter
2. **Verify semver bump** - Version reflects changes
3. **Review values.yaml** - Structure and defaults
4. **Test templates** - `helm template` review
5. **Check documentation** - README accurate
6. **Validate security** - No secrets, good defaults
7. **Consider users** - Breaking changes justified?

## Common Patterns

### Service Account

```yaml
# values.yaml
serviceAccount:
  create: true
  annotations: {}
  name: ""

# templates/serviceaccount.yaml
{{- if .Values.serviceAccount.create -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "chart.serviceAccountName" . }}
  labels:
    {{- include "chart.labels" . | nindent 4 }}
  {{- with .Values.serviceAccount.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}

# templates/_helpers.tpl
{{- define "chart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "chart.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
```

### Security Context

```yaml
# values.yaml
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

### PodDisruptionBudget

```yaml
# values.yaml
podDisruptionBudget:
  enabled: false
  minAvailable: 1
  # maxUnavailable: 1

# templates/poddisruptionbudget.yaml
{{- if .Values.podDisruptionBudget.enabled }}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "chart.fullname" . }}
  labels:
    {{- include "chart.labels" . | nindent 4 }}
spec:
  {{- if .Values.podDisruptionBudget.minAvailable }}
  minAvailable: {{ .Values.podDisruptionBudget.minAvailable }}
  {{- end }}
  {{- if .Values.podDisruptionBudget.maxUnavailable }}
  maxUnavailable: {{ .Values.podDisruptionBudget.maxUnavailable }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "chart.selectorLabels" . | nindent 6 }}
{{- end }}
```

## When in Doubt

1. **Look at existing charts** - We have patterns
2. **Ask questions** - Open an issue or discussion
3. **Start small** - Incremental improvements over big rewrites
4. **Test thoroughly** - Your change affects real deployments
5. **Document the why** - Future you will thank you

## The Philosophy in Action

Every decision in this repository should answer:

1. **Does this help users deploy production workloads?**
2. **Is this the simplest solution that maintains power?**
3. **Is this consistent with our other charts?**
4. **Is this secure by default?**
5. **Will this be maintainable in 6 months?**

If the answer to any is "no," reconsider the approach.

---

## Remember

**We're not just writing YAML. We're crafting tools that help people deploy software reliably.**

Every template you write, every default you choose, every comment you add—it all matters. Someone will use this chart at 2 AM to fix a production issue. Make their life easier.

**Simplicity. Consistency. Security. Production-readiness. Clarity.**

These aren't just words. They're commitments.

Now go build something elegant.
