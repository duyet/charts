# duyet/charts [![Chart Lint](https://github.com/duyet/charts/actions/workflows/chart-lint.yml/badge.svg)](https://github.com/duyet/charts/actions/workflows/chart-lint.yml) [![Build & Publish](https://github.com/duyet/charts/actions/workflows/chart-build-publish.yml/badge.svg)](https://github.com/duyet/charts/actions/workflows/chart-build-publish.yml) [![Artifact HUB](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/duyet)](https://artifacthub.io/packages/search?repo=duyet)

Production-ready Helm Charts for Kubernetes.

**📖 New to this repository?** Read [CLAUDE.md](CLAUDE.md) for the project philosophy and development standards.

- Charts list: https://duyet.github.io/charts/index.yaml
- Artifact hub: https://artifacthub.io/packages/search?repo=duyet

## Available Charts

This repository contains the following Helm charts:

- **[amundsen](./amundsen)** - Metadata driven application for data discovery
- **[applause-btn](./applause-btn)** - Applause button service
- **[clickhouse-keeper](./clickhouse-keeper)** - ClickHouse Keeper for cluster coordination
- **[clickhouse-monitoring](./clickhouse-monitoring)** - ClickHouse monitoring tools
- **[commento](./commento)** - Comment system for websites
- **[gaxy](./gaxy)** - Google Analytics proxy
- **[pgbouncer](./pgbouncer)** - PostgreSQL connection pooler
- **[scheduling-restart](./scheduling-restart)** - Scheduled deployment restarts
- **[spark-shuffle-service](./spark-shuffle-service)** - Spark shuffle service daemon
- **[uptime-kuma](./uptime-kuma)** - Self-hosted uptime monitoring
- **[zeppelin](./zeppelin)** - Apache Zeppelin notebook

## Documentation

- **[CLAUDE.md](CLAUDE.md)** - Project philosophy and development guide *(read this first!)*
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution guidelines and chart standards
- **[SECURITY.md](SECURITY.md)** - Security policy and best practices

# Before You Begin

## Setup a Kubernetes Cluster

There are many way to setup a Kubernetes cluster:
- [Learning environment](https://kubernetes.io/docs/setup/learning-environment/)
- [Production environment](https://kubernetes.io/docs/setup/production-environment/)
- [Best practices](https://kubernetes.io/docs/setup/best-practices/)

## Install Helm

To install Helm, refer to the [Helm install guide](https://github.com/helm/helm#install) and ensure that the `helm` binary is in the `PATH` of your shell.

## Add Repo

The following command allows you to download and install all the charts from this repository:

```
$ helm repo add duyet https://duyet.github.io/charts
```

## Using Helm

Useful Helm Client Commands:

```bash
# View available charts
helm search repo duyet

# Install a chart
helm install my-release duyet/<chart-name>

# Get chart values
helm show values duyet/<chart-name>

# Upgrade your application
helm upgrade my-release duyet/<chart-name>

# Uninstall
helm uninstall my-release
```

## Contributing

We welcome contributions! Please read:

1. **[CLAUDE.md](CLAUDE.md)** - Understand the project philosophy
2. **[CONTRIBUTING.md](CONTRIBUTING.md)** - Follow contribution guidelines
3. **[SECURITY.md](SECURITY.md)** - Review security requirements

All commits must follow [semantic commit conventions](CLAUDE.md#semantic-commits).

## License

MIT
