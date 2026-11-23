# MariaDB 11.8.9 (LTS), official image, pinned by version and digest. GLPI 12 needs MariaDB 10.11 or newer.
FROM mariadb:11.8.9@sha256:e1d5495f445654134f226f55a41ce0da227116f6f27f283101f405c794d841fc

# Database and user GLPI connects as; passwords come from the service variables.
ENV MARIADB_DATABASE=glpi \
    MARIADB_USER=glpi \
    MARIADB_AUTO_UPGRADE=1

COPY railway.cnf /etc/mysql/conf.d/zz-railway.cnf
COPY glpi-timezones.sql /docker-entrypoint-initdb.d/50-glpi-timezones.sql
