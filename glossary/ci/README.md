# Glossary CI coverage

Glossary requires a reachable PostgreSQL database configured through
`env.DATABASE_URL`. The ephemeral chart-testing clusters do not provide one, so
Glossary cannot become ready with its default values. Full install and Helm
connection tests are excluded until a database-aware fixture is available.
Restore install coverage once that fixture provisions PostgreSQL and configures
the application connection in each chart-testing release namespace.

This exclusion applies only to installation. Chart linting and kubeconform
validation remain enabled. The Chart Lint workflow also renders the enabled HPA
with CPU-only, memory-only, and combined utilization targets and validates each
with `kubectl apply --dry-run=server` against every Kubernetes version in the CI
matrix. These checks validate API acceptance, not live scaling behavior; they do
not require PostgreSQL or a metrics server.

Enabled autoscaling uses `autoscaling/v2` and requires Kubernetes 1.23 or later.
Configure resource requests for each selected utilization metric and provide a
metrics server in production. Autoscaling remains disabled by default.
