# Security Policy

## Supported Versions

We provide security updates for the latest version of each chart. Older versions may not receive security patches.

| Chart | Latest Version | Security Updates |
|-------|----------------|------------------|
| All charts | Latest release | ✅ Yes |
| Older versions | - | ❌ No |

## Reporting a Vulnerability

If you discover a security vulnerability in any of these Helm charts, please report it by:

1. **DO NOT** open a public issue
2. Email the maintainer privately (see chart metadata for contact)
3. Include:
   - Chart name and version
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We will acknowledge receipt within 48 hours and provide a detailed response within 7 days.

## Security Best Practices

### For Chart Users

#### 1. Use Specific Image Tags

**Avoid `latest` tags:**
```yaml
# Good
image:
  tag: "1.2.3"

# Bad
image:
  tag: "latest"
```

#### 2. Enable Security Contexts

Always configure security contexts:
```yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
    - ALL
```

#### 3. Set Resource Limits

Prevent resource exhaustion:
```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

#### 4. Use Secrets Properly

**Never** store secrets in values.yaml:
```yaml
# Bad - secrets in plain text
postgresql:
  postgresqlPassword: "mypassword"

# Good - reference existing secret
postgresql:
  existingSecret: "my-secret-name"
```

#### 5. Network Policies

Enable network policies to restrict traffic:
```yaml
networkPolicy:
  enabled: true
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            name: my-namespace
```

#### 6. Image Pull Policy

Use `IfNotPresent` or specific digests:
```yaml
image:
  pullPolicy: IfNotPresent
  # Or use digest for immutability
  # repository: myapp@sha256:abcdef...
```

### For Chart Maintainers

#### 1. Dependency Management

- Keep dependencies updated
- Review dependency changes before upgrading
- Pin dependency versions in `Chart.yaml`
- Run `helm dependency update` regularly

#### 2. Default Security

Provide secure defaults:
- Non-root user by default
- Read-only root filesystem where possible
- Drop all capabilities by default
- Enable `runAsNonRoot: true`

#### 3. Input Validation

Validate user inputs in templates:
```yaml
{{- if not (and .Values.config.url (hasPrefix "https://" .Values.config.url)) }}
  {{- fail "config.url must start with https://" }}
{{- end }}
```

#### 4. RBAC

Implement least-privilege RBAC:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ include "chart.fullname" . }}
rules:
  # Only grant necessary permissions
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list"]
```

#### 5. Secret Management

- Support `existingSecret` parameter
- Don't generate secrets in templates
- Use Kubernetes secrets or external secret managers
- Never log secrets

```yaml
{{- if not .Values.existingSecret }}
  {{- fail "existingSecret must be specified" }}
{{- end }}
```

## Known Security Considerations

### Container Images

These charts reference third-party container images. Users should:

1. **Scan images** for vulnerabilities before deployment
2. **Use private registries** with validated images
3. **Enable image signature verification** when possible
4. **Monitor** for image updates and CVEs

### Dependency Charts

Some charts depend on external charts (e.g., PostgreSQL, Elasticsearch):

1. Review sub-chart security settings
2. Override insecure defaults
3. Keep dependencies updated
4. Test upgrades in non-production first

### Ingress and Exposure

When exposing services:

1. **Always use TLS/HTTPS**
2. **Configure authentication** (OAuth, basic auth, etc.)
3. **Use network policies** to restrict access
4. **Enable rate limiting** to prevent abuse
5. **Keep ingress controller updated**

## Security Checklist

Before deploying to production:

- [ ] Images use specific tags (not `latest`)
- [ ] Security contexts configured
- [ ] Resource limits set
- [ ] Secrets externalized (not in values.yaml)
- [ ] Network policies enabled
- [ ] RBAC follows least privilege
- [ ] TLS/HTTPS configured for exposed services
- [ ] Images scanned for vulnerabilities
- [ ] Dependencies reviewed and updated
- [ ] Monitoring and alerting configured

## Security Tools

### Recommended Tools for Chart Security

1. **Image Scanning**
   - [Trivy](https://github.com/aquasecurity/trivy)
   - [Grype](https://github.com/anchore/grype)

2. **Chart Security Scanning**
   - [Checkov](https://www.checkov.io/)
   - [kubesec](https://kubesec.io/)
   - [kube-score](https://github.com/zegl/kube-score)

3. **Runtime Security**
   - [Falco](https://falco.org/)
   - [Open Policy Agent](https://www.openpolicyagent.org/)

### Example: Scanning a Chart

```bash
# Scan for security issues
helm template ./mychart | kubesec scan -

# Check with kube-score
helm template ./mychart | kube-score score -

# Scan images
trivy image myapp:1.0.0
```

## Updates and Patching

### Dependency Updates

- Renovate bot automatically creates PRs for dependency updates
- Review and test before merging
- Check changelogs for breaking changes

### Security Patches

When a security issue is fixed:

1. Version bump (PATCH for security fixes)
2. Update CHANGELOG
3. Tag release
4. Notify users via GitHub releases

## Compliance

These charts aim to follow:

- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [NSA/CISA Kubernetes Hardening Guide](https://www.nsa.gov/Press-Room/News-Highlights/Article/Article/2716980/)
- [OWASP Kubernetes Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Kubernetes_Security_Cheat_Sheet.html)

Users deploying in regulated environments should review compliance requirements and adjust configurations accordingly.

## Questions?

For security questions or concerns, please reach out via the reporting process above or open a discussion (for non-sensitive topics).

---

**Remember:** Security is a shared responsibility. These charts provide a foundation, but you must configure them appropriately for your environment.
