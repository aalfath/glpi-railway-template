# Changelog

Breaking changes are listed first in each entry.

## 12.0.2 (2026-11-23)

- First version: GLPI 12.0.2 (`glpi/glpi:12.0.2@sha256:8728a93b1d895eb4a275e32d490b4aa588bf305ca034e5d06f22968390cca59e`) with its cron worker, and MariaDB 11.8.9 (`mariadb:11.8.9@sha256:e1d5495f445654134f226f55a41ce0da227116f6f27f283101f405c794d841fc`).
- Unattended install on first start; the `glpi` super-admin gets the generated `GLPI_ADMIN_PASSWORD`; demo accounts `tech`, `normal`, `post-only` are disabled.
