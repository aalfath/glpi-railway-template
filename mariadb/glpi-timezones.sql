-- Lets GLPI read the time zone list (bin/console database:enable_timezones). Runs once, on first start.
GRANT SELECT ON `mysql`.`time_zone_name` TO 'glpi'@'%';
FLUSH PRIVILEGES;
