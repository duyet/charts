# PG Bouncer

This project is a Helm chart implementation for [PgBouncer](https://pgbouncer.github.io/).

Forked from [cradlepoint/kubernetes-helm-chart-pgbouncer](https://github.com/cradlepoint/kubernetes-helm-chart-pgbouncer)

# What's different?

Configurable `auth_type`: 

```yaml
config:
  pgbouncer:
    auth_type: md5
  users:
    # "md5" + md5(password + username)
    postgres: md579d918f6faa49bcd55bec25e79d87b56
```

For example, the username is `postgres` and the password is `123456`, so the password should be:

```
$ echo "md5$(echo 123456postgres | md5)"

md50421b44bd5849bf24190664c35936544
```

# TL;DR

To install the chart with the release name `my-release`:

```shell
$ helm repo add duyet https://duyet.github.io/charts
$ helm install my-release duyet/pgbouncer 
```
