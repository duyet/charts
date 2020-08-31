# PG Bouncer

This project is a Helm chart implementation for [PgBouncer](https://pgbouncer.github.io/).

Forked from [cradlepoint/kubernetes-helm-chart-pgbouncer](https://github.com/cradlepoint/kubernetes-helm-chart-pgbouncer)

# What's different?

- Configurable `auth_type`: 

    ```yaml
    config:
      pgbouncer:
        auth_type: md5
    users:
      # "md5" + md5(password + username)
      postgres: md579d918f6faa49bcd55bec25e79d87b56
    ```