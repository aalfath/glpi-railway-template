#!/bin/bash
# www-data part of the start: install or update GLPI, lock down the default accounts,
# then run Apache and GLPI's cron worker. If either stops, exit non-zero so Railway restarts the service.
set -euo pipefail
cd /var/www/glpi

/opt/glpi/entrypoint/init-volumes-directories.sh
/opt/glpi/entrypoint/forward-logs.sh
/opt/glpi/entrypoint/wait-for-db.sh railway

installed_marker="${GLPI_CONFIG_DIR}/.railway-installed"
hardened_marker="${GLPI_CONFIG_DIR}/.railway-accounts-secured"

if [ -f "$installed_marker" ]; then
  # Installed before. If the database was emptied since (for example a new MariaDB volume), install again.
  set +e; bin/console db:check --no-interaction --quiet; rc=$?; set -e
  if [ "$rc" = 7 ]; then
    echo "[railway] The GLPI database has no tables any more; installing it again."
    rm -f "$installed_marker" "$hardened_marker"
  elif [ "$rc" -ge 5 ]; then
    echo "[railway] ERROR: GLPI cannot use its database (db:check exit $rc)." >&2
    exit 1
  fi
fi

if [ ! -f "$installed_marker" ]; then
  echo "[railway] First start: installing the GLPI database (about a minute)..."
  # --force/--reconfigure: a first install that was interrupted is started again from scratch.
  bin/console database:install \
    --db-host="$GLPI_DB_HOST" --db-port="$GLPI_DB_PORT" --db-name="$GLPI_DB_NAME" \
    --db-user="$GLPI_DB_USER" --db-password="$GLPI_DB_PASSWORD" \
    --default-language="$GLPI_DEFAULT_LANGUAGE" \
    --reconfigure --force --no-interaction --quiet
  # Time zone support (the MariaDB service grants the needed read access); optional.
  bin/console database:enable_timezones --no-interaction --quiet || echo "[railway] Time zone support not enabled (optional)."
  touch "$installed_marker"
  echo "[railway] GLPI database installed."
else
  echo "[railway] GLPI is installed; applying any pending database update..."
  bin/console database:update --no-interaction --quiet
fi

if [ ! -f "$hardened_marker" ]; then
  # GLPI ships four accounts with published passwords. Give the super-admin the generated
  # GLPI_ADMIN_PASSWORD and disable the three demo accounts (random passwords as well).
  bin/console user:reset_password "$GLPI_ADMIN_USER" --password="$GLPI_ADMIN_PASSWORD" --no-interaction --quiet
  for u in tech normal post-only; do
    rnd="$(head -c 32 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 32)"
    bin/console user:reset_password "$u" --password="$rnd" --no-interaction --quiet || true
    bin/console user:disable "$u" --no-interaction --quiet || true
  done
  touch "$hardened_marker"
  echo "[railway] Sign in as '$GLPI_ADMIN_USER' with the password in GLPI_ADMIN_PASSWORD. Demo accounts tech, normal and post-only are disabled."
fi

if [ -n "${GLPI_URL_BASE:-}" ]; then
  bin/console config:set url_base "$GLPI_URL_BASE" --no-interaction --quiet || true
fi

apache2-foreground &
apache_pid=$!
/opt/glpi/cron-worker.sh &
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
