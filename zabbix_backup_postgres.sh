#!/bin/bash

year=$(date +%Y)
month=$(date +%m)
day=$(date +%d)
clock=$(date +%H%M)
volume=/backup/postgres
dest=$volume/$year/$month/$day/$clock

if [ ! -d "$dest" ]; then
  mkdir -p "$dest"
fi

for db in $(
PGPORT=7412 PGPASSWORD=zabbix PGUSER=postgres psql -h 10.133.112.87 -t -A -c "SELECT datname FROM pg_database where datname not in ('template0','template1','postgres','dummy_db')"
) ; do echo $db; PGPORT=7412 PGPASSWORD=zabbix PGUSER=postgres pg_dump -h 10.133.112.87 $db | xz > $dest/$db.sql.xz ; done

rclone -vv sync $volume BackupPostgreSQL:postgres
