#!/bin/bash
# Start script: prepare the Railway volume and port as root, set GLPI up as www-data, then run Apache and GLPI's cron worker.
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

as_www() { setpriv --reuid=www-data --regid=www-data --init-groups "$@"; }

# Install or update GLPI as www-data (file ownership on the volume stays www-data).
as_www /opt/glpi/entrypoint/init-volumes-directories.sh
# GLPI's log files belong to www-data; the stock forwarder (run as root) then tails them into the service logs.
as_www touch "${GLPI_LOG_DIR}"/{event,cron,mail,php-errors,sql-errors,mail-errors,access-errors}.log
/opt/glpi/entrypoint/forward-logs.sh
as_www /opt/railway/setup.sh

# Apache's master runs as root (as in the stock php:apache image) and serves requests from www-data workers.
# GLPI's cron worker runs as www-data. If either stops unexpectedly, exit non-zero so Railway restarts the service.
apache2-foreground &
apache_pid=$!
as_www /opt/glpi/cron-worker.sh &
cron_pid=$!

stopping=0
term() { stopping=1; kill -TERM "$apache_pid" "$cron_pid" 2>/dev/null || true; }
trap term TERM INT

set +e
wait -n "$apache_pid" "$cron_pid"
status=$?
if [ "$stopping" = 1 ]; then
  wait "$apache_pid" "$cron_pid" 2>/dev/null
  exit 0
fi
echo "[railway] A GLPI process stopped unexpectedly (exit $status); exiting so Railway restarts the service." >&2
kill -TERM "$apache_pid" "$cron_pid" 2>/dev/null
exit 1
