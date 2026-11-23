# GLPI 12.0.2, official image (Debian 13, PHP 8.5, Apache prefork), pinned by version and digest.
FROM glpi/glpi:12.0.2@sha256:8728a93b1d895eb4a275e32d490b4aa588bf305ca034e5d06f22968390cca59e

USER root

# Database defaults (the MariaDB service in this template creates exactly this database and user).
# Small-plan defaults: Railway's Free plan gives a service 0.5 GB RAM.
ENV GLPI_DB_PORT=3306 \
    GLPI_DB_NAME=glpi \
    GLPI_DB_USER=glpi \
    GLPI_ADMIN_USER=glpi \
    GLPI_DEFAULT_LANGUAGE=en_GB \
    PORT=8080 \
    APACHE_START_SERVERS=2 \
    APACHE_MAX_WORKERS=8 \
    PHP_MEMORY_LIMIT=256M

COPY mpm_prefork.conf /etc/apache2/mods-available/mpm_prefork.conf
COPY railway-proxy.conf /etc/apache2/conf-available/railway-proxy.conf
COPY start.sh setup.sh /opt/railway/
RUN a2enmod proxy proxy_http >/dev/null \
 && a2enconf railway-proxy >/dev/null \
 && chmod 755 /opt/railway/start.sh /opt/railway/setup.sh

# start.sh prepares the volume as root; GLPI console, cron and Apache workers run as www-data.
ENTRYPOINT ["/opt/railway/start.sh"]
CMD []
