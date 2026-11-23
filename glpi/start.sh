#!/bin/bash
# Root part of the start: prepare the volume and the listening port, then drop to www-data.
set -euo pipefail

for v in GLPI_DB_HOST GLPI_DB_PORT GLPI_DB_NAME GLPI_DB_USER GLPI_DB_PASSWORD GLPI_ADMIN_PASSWORD; do
  if [ -z "${!v:-}" ]; then
    # Refuse to start: without them GLPI would show its public install wizard.
    echo "[railway] ERROR: $v is not set. Set it in the service variables and redeploy." >&2
    exit 1
  fi
done

# Railway volumes are mounted root-owned; GLPI runs as www-data.
mkdir -p /var/glpi
chown www-data:www-data /var/glpi
find /var/glpi -xdev -mindepth 1 -maxdepth 1 ! -name lost+found ! -user www-data -exec chown -R www-data:www-data {} +

# Listen on Railway's PORT.
echo "Listen ${PORT}" > /etc/apache2/ports.conf
sed -i -E "s#<VirtualHost \*:[0-9]+>#<VirtualHost *:${PORT}>#" /etc/apache2/sites-available/000-default.conf
echo "memory_limit = ${PHP_MEMORY_LIMIT}" > "$PHP_INI_DIR/conf.d/zz-railway.ini"

exec setpriv --reuid=www-data --regid=www-data --init-groups /opt/railway/run.sh
