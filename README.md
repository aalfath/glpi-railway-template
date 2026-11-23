[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/glpi-1?utm_medium=integration&utm_source=button&utm_campaign=glpi)

# GLPI on Railway

One-click [Railway](https://railway.com) template for [GLPI](https://glpi-project.org) **12.0.2**, the open-source IT asset management and service desk (GPL-3.0). Every service builds from this repository, so when we bump the version here, Railway offers deployers an update.

## What the template deploys

| Service | Built from | What it does |
|---|---|---|
| `GLPI` (public) | [`glpi/`](glpi) | The official image `glpi/glpi:12.0.2` (Apache + PHP 8.5) with GLPI's scheduled-task worker in the same service. Installs the database on first start, updates it on later starts. Volume at `/var/glpi` (config, encryption key, documents, plugins, logs). Health check `/healthz` (GLPI's `/status.php`). |
| `MariaDB` | [`mariadb/`](mariadb) | The official image `mariadb:11.8.9` (LTS), sized for small plans (128 MB buffer pool). Creates the `glpi` database and user. Volume at `/var/lib/mysql`. |

Upstream images are pinned by version and digest in each `Dockerfile`.

## After deploy

1. Wait for `GLPI` to turn green (the first start installs the database: about 1–2 minutes).
2. Open the `GLPI` public URL and sign in as **`glpi`** with the password in the `GLPI` service's `GLPI_ADMIN_PASSWORD` variable (generated at deploy). The demo accounts `tech`, `normal` and `post-only` are disabled, and their published default passwords are replaced.
3. Change the password from your avatar menu. The variable is read on the first start only, so changing it later has no effect on the account.
4. Optional: email notifications (**Setup → Notifications**), LDAP/SSO (**Setup → Authentication**) and inventory agents (**Administration → Inventory**) are set up inside GLPI.

## Variables

All are set by the template; nothing has to be typed in.

| Service | Variable | Value |
|---|---|---|
| `GLPI` | `GLPI_ADMIN_PASSWORD` | Generated 24-character password for the `glpi` super-admin, set on first start only |
| `GLPI` | `GLPI_DB_HOST`, `GLPI_DB_PASSWORD` | References to the `MariaDB` service |
| `GLPI` | `GLPI_URL_BASE` | `https://` + the service's Railway domain (links in emails and the API). Change it if you add your own domain |
| `GLPI` | `PORT` | `8080` |
| `MariaDB` | `MARIADB_PASSWORD`, `MARIADB_ROOT_PASSWORD` | Generated |
| `MariaDB` | `RAILWAY_DEPLOYMENT_DRAINING_SECONDS` | `60`, so a redeploy lets MariaDB shut down cleanly |

Fixed settings live in the Dockerfiles and can be overridden with a service variable: `GLPI_DB_NAME`/`GLPI_DB_USER` (`glpi`), `GLPI_DEFAULT_LANGUAGE` (`en_GB`, used at install), `PHP_MEMORY_LIMIT` (`256M`), `APACHE_MAX_WORKERS` (`6`), `GLPI_CRONTAB_ENABLED` (`1`).

## Resources

The stack runs on Railway's smallest plans: in our tests with each service capped at 0.5 GB RAM / 1 vCPU, GLPI peaked at about 100 MB and MariaDB at about 270 MB. On bigger plans, raise `APACHE_MAX_WORKERS` on `GLPI` and `innodb_buffer_pool_size` in [`mariadb/railway.cnf`](mariadb/railway.cnf).

If Apache or the cron worker stops unexpectedly, the `GLPI` service exits with an error so Railway restarts it.

## Updates

When this repository moves to a new GLPI or MariaDB version, Railway shows deployers an "update available" notice; read [`CHANGELOG.md`](CHANGELOG.md) before you apply it. On start, GLPI applies pending database migrations itself (`bin/console database:update`). Take a backup of the `MariaDB` volume first (Railway volume backups, or `mariadb-dump`).

## Licence

GLPI is GPL-3.0 and MariaDB is GPL-2.0; see their projects for the licence texts.
