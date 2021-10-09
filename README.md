# duyet/charts ![Helm Template Validation](https://github.com/duyet/charts/workflows/Helm%20Template%20Validation/badge.svg) [![Artifact HUB](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/duyet)](https://artifacthub.io/packages/search?repo=duyet)
Helm Charts for Kubernetes.

- Charts list: https://duyet.github.io/charts/index.yaml
- Artifact hub: https://artifacthub.io/packages/search?repo=duyet

# Before you begin

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

- View available charts: `helm search repo`
- Install a chart: `helm install my-release duyet/<package-name>`
- Upgrade your application: `helm upgrade`

# License

MIT
