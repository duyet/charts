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
| elasticsearch.client.replicas | int | `1` | only running amundsen on 1 client replica |
| elasticsearch.cluster.env.EXPECTED_MASTER_NODES | int | `1` | required to match master.replicas |
| elasticsearch.cluster.env.MINIMUM_MASTER_NODES | int | `1` | required to match master.replicas |
| elasticsearch.cluster.env.RECOVER_AFTER_MASTER_NODES | int | `1` | required to match master.replicas |
| elasticsearch.data.replicas | int | `1` | only running amundsen on 1 data replica |
| elasticsearch.enabled | bool | `true` | set this to false, if you want to provide your own ES instance. |
| elasticsearch.master.replicas | int | `1` | only running amundsen on 1 master replica |
| frontEnd.affinity | object | `{}` |  |
| frontEnd.annotations | object | `{}` |  |
| frontEnd.baseUrl | string | `"http://localhost"` | used by notifications util to provide links to amundsen pages in emails. |
| frontEnd.createOidcSecret | bool | `false` | OIDC needs some configuration. If you want the chart to make your secrets, set this to true and set the next four values. If you don't want to configure your secrets via helm, you can still use the amundsen-oidc-config.yaml as a template |
| frontEnd.env | object | `{"OIDC_AUTH_SERVER_ID":null,"OIDC_CLIENT_ID":null,"OIDC_CLIENT_SECRET":"","OIDC_ORG_URL":null,"PREVIEW_DATA_DB_CONN_STRING":null,"PREVIEW_DATA_STORAGE_SCHEMA":null,"PREVIEW_DATA_STORAGE_TABLE_NAME":null}` |  Environments |
| frontEnd.env.OIDC_AUTH_SERVER_ID | string | `nil` | The authorization server id for OIDC. |
| frontEnd.env.OIDC_CLIENT_ID | string | `nil` | The client id for OIDC. |
| frontEnd.env.OIDC_CLIENT_SECRET | string | `""` | The client secret for OIDC. |
| frontEnd.env.OIDC_ORG_URL | string | `nil` | The organization URL for OIDC. |
| frontEnd.extraEnvVarsCM | string | `nil` |  |
| frontEnd.extraEnvVarsSecret | string | `nil` |  |
| frontEnd.image | string | `"amundsendev/amundsen-frontend"` | The image of the frontend container. |
| frontEnd.imageTag | string | `"2.1.1"` | The image tag of the frontend container. |
| frontEnd.ingress.annotations | object | `{}` |  |
| frontEnd.ingress.enabled | bool | `false` |  |
| frontEnd.ingress.hosts[0] | string | `"frontend.example.com"` |  |
| frontEnd.ingress.path | string | `"/"` |  |
| frontEnd.ingress.tls | list | `[]` |  |
| frontEnd.nodeSelector | object | `{}` |  |
| frontEnd.oidcEnabled | bool | `false` | To enable auth via OIDC, set this to true. |
| frontEnd.podAnnotations | object | `{}` |  |
| frontEnd.replicas | int | `1` | How many replicas of the frontend service to run. |
| frontEnd.resources | object | `{}` | See pod resourcing [ref](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/) |
| frontEnd.serviceName | string | `"frontend"` | The frontend service name. |
| frontEnd.servicePort | int | `80` | The port the frontend service will be exposed on via the loadbalancer. |
| frontEnd.serviceType | string | `"ClusterIP"` | The frontend service type. See service types [ref](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| frontEnd.tolerations | list | `[]` |  |
| fullNameOverride | string | `""` |  |
| metadata.affinity | object | `{}` |  |
| metadata.annotations | object | `{}` |  |
| metadata.image | string | `"amundsendev/amundsen-metadata"` | The image of the metadata container. |
| metadata.imageTag | string | `"2.5.4"` | The image tag of the metadata container. |
| metadata.neo4jEndpoint | string | `nil` | The name of the service hosting neo4j on your cluster, if you bring your own. You should only need to change this, if you don't use the version in this chart. |
| metadata.nodeSelector | object | `{}` |  |
| metadata.podAnnotations | object | `{}` |  |
| metadata.replicas | int | `1` | How many replicas of the metadata service to run. |
| metadata.resources | object | `{}` | See pod resourcing [ref](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/) |
| metadata.serviceName | string | `"metadata"` | The metadata service name. |
| metadata.serviceType | string | `"ClusterIP"` | The metadata service type. See service types [ref](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| metadata.tolerations | list | `[]` |  |
| nameOverride | string | `""` |  |
| neo4j.affinity | object | `{}` |  |
| neo4j.annotations | object | `{}` |  |
| neo4j.authEnabled | bool | `false` |  |
| neo4j.backup | object | `{"enabled":false,"podAnnotations":{},"s3Path":"s3://dev/null","schedule":"0 * * * *"}` | If enabled is set to true, make sure and set the s3 path as well. |
| neo4j.backup.s3Path | string | `"s3://dev/null"` | The s3path to write to for backups. |
| neo4j.backup.schedule | string | `"0 * * * *"` | The schedule to run backups on. Defaults to hourly. |
| neo4j.config | object | `{"dbms":{"heap_initial_size":"1G","heap_max_size":"2G","pagecache_size":"2G"}}` | Neo4j application specific configuration. This type of configuration is why the charts/stable version is not used. See [ref](https://github.com/helm/charts/issues/21439) |
| neo4j.config.dbms | object | `{"heap_initial_size":"1G","heap_max_size":"2G","pagecache_size":"2G"}` | dbms config for neo4j |
| neo4j.config.dbms.heap_initial_size | string | `"1G"` | the initial java heap for neo4j |
| neo4j.config.dbms.heap_max_size | string | `"2G"` | the max java heap for neo4j |
| neo4j.config.dbms.pagecache_size | string | `"2G"` | the page cache size for neo4j |
| neo4j.enabled | bool | `true` |  |
| neo4j.neo4jEndpoint | string | `nil` | Use external neo4j endpoint |
| neo4j.nodeSelector | object | `{}` |  |
| neo4j.persistence | object | `{}` | Neo4j persistence. Turn this on to keep your data between pod crashes, etc. This is also needed for backups. |
| neo4j.podAnnotations | object | `{}` |  |
| neo4j.resources | object | `{}` |  |
| neo4j.tolerations | list | `[]` |  |
| neo4j.version | string | `"3.3.0"` | The neo4j application version used by amundsen. |
| nodeSelector | object | `{}` |  |
| podAnnotations | object | `{}` |  |
| search.affinity | object | `{}` |  |
| search.annotations | object | `{}` |  |
| search.elasticsearchEndpoint | string | `nil` | The name of the service hosting elasticsearch on your cluster, if you bring your own. You should only need to change this, if you don't use the version in this chart. |
| search.image | string | `"amundsendev/amundsen-search"` | The image of the search container. |
| search.imageTag | string | `"2.4.0"` | The image tag of the search container. |
| search.nodeSelector | object | `{}` |  |
| search.podAnnotations | object | `{}` |  |
| search.replicas | int | `1` | How many replicas of the search service to run. |
| search.resources | object | `{}` | See pod resourcing [ref](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/) |
| search.serviceName | string | `"search"` | The search service name. |
| search.serviceType | string | `"ClusterIP"` | The search service type. See service types [ref](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| search.tolerations | list | `[]` |  |
| tolerations | list | `[]` |  |
