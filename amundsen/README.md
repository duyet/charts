# amundsen

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![AppVersion: 1.0](https://img.shields.io/badge/AppVersion-1.0-informational?style=flat-square)

Amundsen is a metadata driven application for improving the productivity of data analysts, data scientists and engineers when interacting with data.

**Homepage:** <https://github.com/lyft/amundsen>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| duyet | me@duyet.net |  |

## Source Code

* <https://github.com/lyft/amundsen>
* <https://github.com/duyet/charts/amundsen>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://kubernetes-charts.storage.googleapis.com/ | elasticsearch | 1.32.5 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| LONG_RANDOM_STRING | int | `1234` | A long random string. You should probably provide your own. This is needed for OIDC. |
| affinity | object | `{}` |  |
| elasticsearch.client.replicas | int | `1` |  |
| elasticsearch.cluster.env.EXPECTED_MASTER_NODES | int | `1` |  |
| elasticsearch.cluster.env.MINIMUM_MASTER_NODES | int | `1` |  |
| elasticsearch.cluster.env.RECOVER_AFTER_MASTER_NODES | int | `1` |  |
| elasticsearch.data.replicas | int | `1` |  |
| elasticsearch.enabled | bool | `true` | set this to false, if you want to provide your own ES instance. |
| elasticsearch.master.replicas | int | `1` |  |
| frontEnd.affinity | object | `{}` |  |
| frontEnd.annotations | object | `{}` |  |
| frontEnd.baseUrl | string | `"http://localhost"` |  |
| frontEnd.createOidcSecret | bool | `false` |  |
| frontEnd.env.OIDC_AUTH_SERVER_ID | string | `nil` |  |
| frontEnd.env.OIDC_CLIENT_ID | string | `nil` |  |
| frontEnd.env.OIDC_CLIENT_SECRET | string | `""` |  |
| frontEnd.env.OIDC_ORG_URL | string | `nil` |  |
| frontEnd.env.PREVIEW_DATA_DB_CONN_STRING | string | `nil` |  |
| frontEnd.env.PREVIEW_DATA_STORAGE_SCHEMA | string | `nil` |  |
| frontEnd.env.PREVIEW_DATA_STORAGE_TABLE_NAME | string | `nil` |  |
| frontEnd.extraEnvVarsCM | string | `nil` |  |
| frontEnd.extraEnvVarsSecret | string | `nil` |  |
| frontEnd.image | string | `"amundsendev/amundsen-frontend"` |  |
| frontEnd.imageTag | string | `"2.1.1"` |  |
| frontEnd.ingress.annotations | object | `{}` |  |
| frontEnd.ingress.enabled | bool | `false` |  |
| frontEnd.ingress.hosts[0] | string | `"frontend.example.com"` |  |
| frontEnd.ingress.path | string | `"/"` |  |
| frontEnd.ingress.tls | list | `[]` |  |
| frontEnd.nodeSelector | object | `{}` |  |
| frontEnd.oidcEnabled | bool | `false` |  |
| frontEnd.podAnnotations | object | `{}` |  |
| frontEnd.replicas | int | `1` |  |
| frontEnd.resources | object | `{}` |  |
| frontEnd.serviceName | string | `"frontend"` |  |
| frontEnd.servicePort | int | `80` |  |
| frontEnd.serviceType | string | `"ClusterIP"` |  |
| frontEnd.tolerations | list | `[]` |  |
| fullNameOverride | string | `""` |  |
| metadata.affinity | object | `{}` |  |
| metadata.annotations | object | `{}` |  |
| metadata.image | string | `"amundsendev/amundsen-metadata"` |  |
| metadata.imageTag | string | `"2.5.4"` |  |
| metadata.neo4jEndpoint | string | `nil` |  |
| metadata.nodeSelector | object | `{}` |  |
| metadata.podAnnotations | object | `{}` |  |
| metadata.replicas | int | `1` |  |
| metadata.resources | object | `{}` |  |
| metadata.serviceName | string | `"metadata"` |  |
| metadata.serviceType | string | `"ClusterIP"` |  |
| metadata.tolerations | list | `[]` |  |
| nameOverride | string | `""` |  |
| neo4j.affinity | object | `{}` |  |
| neo4j.annotations | object | `{}` |  |
| neo4j.authEnabled | bool | `false` |  |
| neo4j.backup.enabled | bool | `false` |  |
| neo4j.backup.podAnnotations | object | `{}` |  |
| neo4j.backup.s3Path | string | `"s3://dev/null"` |  |
| neo4j.backup.schedule | string | `"0 * * * *"` |  |
| neo4j.config.dbms.heap_initial_size | string | `"1G"` |  |
| neo4j.config.dbms.heap_max_size | string | `"2G"` |  |
| neo4j.config.dbms.pagecache_size | string | `"2G"` |  |
| neo4j.enabled | bool | `true` |  |
| neo4j.neo4jEndpoint | string | `nil` |  |
| neo4j.nodeSelector | object | `{}` |  |
| neo4j.persistence | object | `{}` |  |
| neo4j.podAnnotations | object | `{}` |  |
| neo4j.resources | object | `{}` |  |
| neo4j.tolerations | list | `[]` |  |
| neo4j.version | string | `"3.3.0"` |  |
| nodeSelector | object | `{}` |  |
| podAnnotations | object | `{}` |  |
| search.affinity | object | `{}` |  |
| search.annotations | object | `{}` |  |
| search.elasticsearchEndpoint | string | `nil` |  |
| search.image | string | `"amundsendev/amundsen-search"` |  |
| search.imageTag | string | `"2.4.0"` |  |
| search.nodeSelector | object | `{}` |  |
| search.podAnnotations | object | `{}` |  |
| search.replicas | int | `1` |  |
| search.resources | object | `{}` |  |
| search.serviceName | string | `"search"` | The search service name. |
| search.serviceType | string | `"ClusterIP"` |  |
| search.tolerations | list | `[]` |  |
| tolerations | list | `[]` |  |
