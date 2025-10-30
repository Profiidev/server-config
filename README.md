# Server Config

Terraform scripts for my personal server setup.

## Postgres

Edit the postgres config with this cmd

```bash
kubectl edit perconapgclusters.pgv2.percona.com -n everest postgresql
```

And replace/add to the spec > proxy > pgBouncer > config section

```yaml
global:
  stats_users: _crunchypgbouncer
  max_user_connections: "1000"
```
